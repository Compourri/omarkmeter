#!/usr/bin/env python3
import json
import os
import re
import signal
import urllib.error
import urllib.parse
import urllib.request

MAX_RESPONSE_BYTES = 256 * 1024
READ_CHUNK_BYTES = 8192
TOTAL_TIMEOUT_SECONDS = 8
LOCATION_FILE = os.path.expanduser("~/.local/state/omarchy/settings/weather.json")

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


class NoRedirectHandler(urllib.request.HTTPRedirectHandler):
    def _block(self, req, fp, code, msg, headers):
        raise urllib.error.HTTPError(req.full_url, code, msg, headers, fp)

    http_error_301 = _block
    http_error_302 = _block
    http_error_303 = _block
    http_error_307 = _block
    http_error_308 = _block


def read_location_query():
    """Reuse Omarchy's shared weather location (weather.json) when present."""
    try:
        with open(LOCATION_FILE, "r", encoding="utf-8") as fh:
            data = json.load(fh)
    except (OSError, ValueError, TypeError):
        return ""
    if not isinstance(data, dict):
        return ""
    name = data.get("name")
    name = name.strip() if isinstance(name, str) else ""
    lat = data.get("latitude")
    lon = data.get("longitude")
    try:
        lat_f = float(lat)
        lon_f = float(lon)
    except (TypeError, ValueError):
        lat_f = lon_f = None
    if lat_f is not None and lon_f is not None and not (lat_f != lat_f or lon_f != lon_f):
        return f"{lat_f},{lon_f}"
    if name:
        return urllib.parse.quote(name, safe="")
    return ""


def fetch_weather():
    query = read_location_query()
    if query:
        url = "https://wttr.in/" + query + "?format=j1"
    else:
        url = "https://wttr.in/?format=j1"
    req = urllib.request.Request(url, headers={"User-Agent": "curl/8.0.0"})
    opener = urllib.request.build_opener(NoRedirectHandler)
    # socket timeout only covers individual reads; the alarm bounds the whole
    # fetch so a slow or never-ending response cannot occupy the helper.
    signal.signal(signal.SIGALRM, _expire)
    signal.setitimer(signal.ITIMER_REAL, TOTAL_TIMEOUT_SECONDS)
    try:
        with opener.open(req, timeout=TOTAL_TIMEOUT_SECONDS) as resp:
            if getattr(resp, "status", 200) >= 300:
                raise urllib.error.HTTPError(url, resp.status, "redirect or error", resp.headers, None)
            chunks = []
            remaining = MAX_RESPONSE_BYTES
            while remaining > 0:
                chunk = resp.read(min(READ_CHUNK_BYTES, remaining))
                if not chunk:
                    break
                chunks.append(chunk)
                remaining -= len(chunk)
            # A response that fills the cap is treated as untrusted/oversized.
            if remaining == 0:
                raise ValueError("response too large")
        return json.loads(b"".join(chunks).decode("utf-8"))
    finally:
        signal.setitimer(signal.ITIMER_REAL, 0)


TEMP_RE = re.compile(r"^-?\d+(?:\.\d+)?$")


def safe_desc(value):
    if not isinstance(value, str):
        return ""
    # Keep only characters that can legitimately appear in a weather description.
    cleaned = re.sub(r"[^A-Za-z0-9 ]+", " ", value).strip().upper()
    cleaned = re.sub(r"\s+", " ", cleaned)
    return cleaned


try:
    data = fetch_weather()
    curr = data.get("current_condition", [{}])[0] if isinstance(data, dict) else {}
    temp_c = curr.get("temp_C", "--") if isinstance(curr, dict) else "--"
    if not (isinstance(temp_c, str) and TEMP_RE.match(temp_c.strip())):
        temp_c = "--"
    desc = safe_desc(curr.get("weatherDesc", [{}])[0].get("value", "") if isinstance(curr, dict) else "")
    icon = ICONS.get(desc, "\u2600")
    if temp_c == "--" or not desc:
        print("--|--|--")
    else:
        print(f"{icon}|{desc}|{temp_c}\u00b0C")
except Exception:
    print("--|--|--")
