#!/usr/bin/env python3
import json
import signal
import urllib.request

MAX_RESPONSE_BYTES = 256 * 1024
READ_CHUNK_BYTES = 8192
TOTAL_TIMEOUT_SECONDS = 8

ICONS = {
    "SUNNY": "\u2600", "CLEAR": "\u2600",
    "PARTLY CLOUDY": "\u26c5", "LIGHT CLOUD": "\u26c5",
    "OVERCAST": "\u2601", "CLOUDY": "\u2601", "MOSTLY CLOUDY": "\u2601",
    "MIST": "\ud83c\udf2b", "FOG": "\ud83c\udf2b",
    "LIGHT RAIN": "\ud83c\udf26", "RAIN": "\ud83c\udf27", "SHOWERS": "\ud83c\udf27",
    "HEAVY RAIN": "\ud83c\udf27",
    "THUNDERSTORM": "\u26c8", "LIGHT THUNDERSTORM": "\u26c8",
    "SNOW": "\u2744", "LIGHT SNOW": "\u2744", "HEAVY SNOW": "\u2744",
    "DRIZZLE": "\ud83c\udf26",
}

class FetchTimeout(Exception):
    pass


def _expire(signum, frame):
    raise FetchTimeout()


def fetch_weather():
    url = "https://wttr.in/?format=j1"
    req = urllib.request.Request(url, headers={"User-Agent": "curl/8.0.0"})
    # socket timeout only covers individual reads; the alarm bounds the whole
    # fetch so a slow or never-ending response cannot occupy the helper.
    signal.signal(signal.SIGALRM, _expire)
    signal.setitimer(signal.ITIMER_REAL, TOTAL_TIMEOUT_SECONDS)
    try:
        with urllib.request.urlopen(req, timeout=TOTAL_TIMEOUT_SECONDS) as resp:
            chunks = []
            remaining = MAX_RESPONSE_BYTES
            while remaining > 0:
                chunk = resp.read(min(READ_CHUNK_BYTES, remaining))
                if not chunk:
                    break
                chunks.append(chunk)
                remaining -= len(chunk)
        return json.loads(b"".join(chunks).decode("utf-8"))
    finally:
        signal.setitimer(signal.ITIMER_REAL, 0)


try:
    data = fetch_weather()
    curr = data.get("current_condition", [{}])[0]
    temp_c = curr.get("temp_C", "--")
    desc = curr.get("weatherDesc", [{}])[0].get("value", "").strip().upper()
    icon = ICONS.get(desc, "\u2600")
    if temp_c == "--":
        print("--|--|--")
    else:
        print(f"{icon}|{desc}|{temp_c}\u00b0C")
except Exception:
    print("--|--|--")