#!/usr/bin/env python3
import subprocess
import sys
import numpy as np

RATE = 48000
CHANNELS = 2
FRAME = 4096
NBARS = 60


def get_monitor():
    try:
        p = subprocess.run(['pactl', 'get-default-sink'], capture_output=True, text=True, timeout=2)
        sink = p.stdout.strip()
        if sink:
            q = subprocess.run(['pactl', 'list', 'short', 'sources'], capture_output=True, text=True, timeout=2)
            for line in q.stdout.splitlines():
                parts = line.split()
                if len(parts) > 1 and parts[1] == sink + '.monitor':
                    return parts[1]
    except Exception:
        pass
    return None


def main():
    dev = get_monitor()
    if not dev:
        sys.exit(1)
    try:
        proc = subprocess.Popen(
            ['parec', '--raw', '--format=float32le',
             f'--rate={RATE}', f'--channels={CHANNELS}', f'--device={dev}'],
            stdout=subprocess.PIPE)
    except Exception:
        sys.exit(1)

    win = np.hanning(FRAME).astype(np.float32)
    freqs = np.fft.rfftfreq(FRAME, 1.0 / RATE)
    edges = np.geomspace(40.0, 11000.0, NBARS + 1)
    bin_idx = np.searchsorted(edges, freqs, side='right') - 1
    valid = bin_idx >= 0

    smooth_bands = np.full(NBARS, 0.05, dtype=np.float32)
    frame_bytes = FRAME * CHANNELS * 4

    while True:
        data = proc.stdout.read(frame_bytes)
        if not data or len(data) < frame_bytes:
            if proc.poll() is not None:
                break
            continue
        a = np.frombuffer(data, dtype=np.float32).reshape(-1, CHANNELS)
        mono = a.mean(axis=1)
        peak_in = float(np.max(np.abs(mono)))
        if peak_in < 1e-4:
            smooth_bands *= 0.8
        else:
            seg = mono * win
            power = np.abs(np.fft.rfft(seg)) ** 2
            power_sum = np.bincount(bin_idx[valid], weights=power[valid], minlength=NBARS + 1)[:NBARS]
            counts = np.bincount(bin_idx[valid], minlength=NBARS + 1)[:NBARS]
            levels = power_sum / np.maximum(counts, 1)
            db = 10.0 * np.log10(levels + 1e-12)
            peak_db = float(np.max(db))
            norm = np.clip((db - (peak_db - 45.0)) / 45.0, 0.0, 1.0).astype(np.float32)
            kernel = np.array([0.25, 0.5, 0.25], dtype=np.float32)
            norm = np.convolve(norm, kernel, mode='same')
            smooth_bands = np.where(norm > smooth_bands,
                                    smooth_bands * 0.6 + norm * 0.4,
                                    smooth_bands * 0.9 + norm * 0.1)
        sys.stdout.write(','.join(f'{v:.4f}' for v in smooth_bands) + '\n')
        sys.stdout.flush()


if __name__ == '__main__':
    main()