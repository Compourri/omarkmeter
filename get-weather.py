#!/usr/bin/env python3
import urllib.request
import json

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

try:
    url = "https://wttr.in/?format=j1"
    req = urllib.request.Request(url, headers={"User-Agent": "curl/8.0.0"})
    with urllib.request.urlopen(req, timeout=8) as resp:
        data = json.loads(resp.read().decode("utf-8"))
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