#!/usr/bin/env python3
import os
import json
import time

def format_bytes(n):
    for unit in ['B', 'K', 'M', 'G', 'T']:
        if n < 1024.0:
            return f"{n:.1f}{unit}" if unit != 'B' else f"{n:.0f}{unit}"
        n /= 1024.0
    return f"{n:.1f}P"

def get_cpu_pct():
    try:
        with open('/proc/stat', 'r') as f:
            values = [float(x) for x in f.readline().split()[1:]]
        idle1 = values[3] + values[4]
        total1 = sum(values)
        time.sleep(0.1)
        with open('/proc/stat', 'r') as f:
            values = [float(x) for x in f.readline().split()[1:]]
        idle2 = values[3] + values[4]
        total2 = sum(values)

        total_delta = total2 - total1
        idle_delta = idle2 - idle1
        if total_delta > 0:
            cpu_usage = 1.0 - (idle_delta / total_delta)
            return max(0.0, min(1.0, cpu_usage))
    except Exception:
        pass
    return 0.0

def get_disk_pct(mount):
    try:
        st = os.statvfs(mount)
        total = st.f_blocks * st.f_frsize
        free = st.f_bavail * st.f_frsize
        used = total - free
        return used, total, used / total if total > 0 else 0.0
    except Exception:
        return 0, 1, 0.0

def get_physical_disks():
    import subprocess
    try:
        out = subprocess.run(["lsblk", "-J", "-b", "-o", "NAME,TYPE,SIZE,KNAME,MOUNTPOINTS"],
                             capture_output=True, text=True, timeout=5).stdout
        tree = json.loads(out)["blockdevices"]
    except Exception:
        return []
    disks = []
    for dev in tree:
        if dev.get("type") != "disk":
            continue
        name = dev.get("name", "")
        if any(name.startswith(p) for p in ("zram", "loop", "sr", "ram")):
            continue
        # Collate every descendant block device (partitions, dm-crypt mappers)
        # so df sources can be attributed to this physical disk. KNAME is a
        # bare name (nvme0n1, dm-0); canonical /dev path comes from realpath.
        sources = []
        def walk(node):
            kn = node.get("kname", "")
            if kn:
                candidates = [f"/dev/{kn}", kn]
                sources.extend(candidates)
            for ch in node.get("children", []) or []:
                walk(ch)
        walk(dev)
        disks.append({"name": name, "size": int(dev.get("size", 0)), "used": 0, "pct": 0.0, "sources": sources})
    return disks

def attach_disk_usage(disks):
    if not disks:
        return disks
    try:
        import subprocess
        out = subprocess.run(["df", "-B1", "--output=source,used,size"],
                             capture_output=True, text=True, timeout=5).stdout
    except Exception:
        for d in disks:
            d.pop("sources", None)
        return disks
    used_by_src = {}
    for line in out.strip().splitlines()[1:]:
        parts = line.split()
        if len(parts) < 3 or not parts[0].startswith("/dev/"):
            continue
        used_by_src[parts[0]] = int(parts[1])

    def canon(a):
        try:
            return os.path.realpath(a)
        except Exception:
            return a

    canon_used = {canon(s): v for s, v in used_by_src.items()}
    for d in disks:
        d["used"] = sum(canon_used.get(canon(s), 0) for s in d.get("sources", []))
        if d["size"] > 0:
            d["pct"] = min(1.0, d["used"] / d["size"])
        d["size_str"] = format_bytes(d["size"])
        d["used_str"] = format_bytes(d["used"])
    return disks
    return disks

def read_net(path):
    try:
        with open(path, 'r') as f:
            return int(f.readline().strip())
    except Exception:
        return 0

def get_stats():
    rx1, tx1 = read_net('/sys/class/net/eth0/statistics/rx_bytes'), read_net('/sys/class/net/eth0/statistics/tx_bytes')
    try:
        import glob
        nets = glob.glob('/sys/class/net/*')
        rx1 = tx1 = 0
        for n in nets:
            name = os.path.basename(n)
            if name == 'lo':
                continue
            rx1 += read_net(n + '/statistics/rx_bytes')
            tx1 += read_net(n + '/statistics/tx_bytes')
    except Exception:
        pass

    time.sleep(1.0)
    disks = attach_disk_usage(get_physical_disks())
    ram_pct = 0.0
    try:
        with open('/proc/meminfo', 'r') as f:
            lines = f.readlines()
            mem_total = 0
            mem_avail = 0
            for line in lines:
                if line.startswith('MemTotal:'):
                    mem_total = int(line.split()[1]) * 1024
                elif line.startswith('MemAvailable:'):
                    mem_avail = int(line.split()[1]) * 1024
            if mem_total > 0:
                mem_used = mem_total - mem_avail
                ram_pct = mem_used / mem_total
    except Exception:
        pass

    rx2, tx2 = 0, 0
    try:
        import glob
        for n in glob.glob('/sys/class/net/*'):
            name = os.path.basename(n)
            if name == 'lo':
                continue
            rx2 += read_net(n + '/statistics/rx_bytes')
            tx2 += read_net(n + '/statistics/tx_bytes')
    except Exception:
        pass
    net_down = max(0, rx2 - rx1) * 8
    net_up = max(0, tx2 - tx1) * 8

    cpu_pct = get_cpu_pct()

    def bps(v):
        if v >= 1_000_000:
            return f"{v/1_000_000:.1f} Mbps"
        if v >= 1_000:
            return f"{v/1_000:.1f} Kbps"
        return f"{v:.0f} bps"

    out = {
        "disks": [{"name": d["name"], "size": d.get("size_str", "0B"),
                   "used": d.get("used_str", "0B"), "pct": d.get("pct", 0.0)}
                  for d in disks],
        "ram_pct": round(ram_pct, 2),
        "ram_str": f"{int(ram_pct * 100)}%",
        "cpu_pct": round(cpu_pct, 2),
        "cpu_str": f"{int(cpu_pct * 100)}%",
        "net_up": bps(net_up),
        "net_down": bps(net_down)
    }
    print(json.dumps(out))

if __name__ == "__main__":
    get_stats()