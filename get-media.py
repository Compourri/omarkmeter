#!/usr/bin/env python3
import dbus

BUS_NAME_PREFIX = "org.mpris.MediaPlayer2."
PLAYER_IFACE = "org.mpris.MediaPlayer2.Player"
ROOT_IFACE = "org.mpris.MediaPlayer2"
PROPS = "org.freedesktop.DBus.Properties"

def get_playing():
    try:
        bus = dbus.SessionBus()
        names = bus.list_names()
    except Exception:
        return "|"
    players = [n for n in names if n.startswith(BUS_NAME_PREFIX)]
    players.sort(key=lambda n: 0 if "brave" in n else 1)
    for player in players:
        try:
            player_obj = bus.get_object(player, "/org/mpris/MediaPlayer2")
            props = dbus.Interface(player_obj, PROPS)
            status = str(props.Get(PLAYER_IFACE, "PlaybackStatus"))
            if status == "Stopped":
                continue
            metadata = props.Get(PLAYER_IFACE, "Metadata")
        except Exception:
            continue
        title = ""
        artist = ""
        try:
            title = str(metadata.get("xesam:title", ""))
        except Exception:
            title = ""
        try:
            art = metadata.get("xesam:artist", [])
            if isinstance(art, list) and art:
                artist = str(art[0])
            elif art:
                artist = str(art)
        except Exception:
            artist = ""
        if title:
            return f"{artist.upper()}|{title.upper()}"
    return "|"

if __name__ == "__main__":
    print(get_playing())