#!/usr/bin/env python3
"""MPRIS control via playerctl. JSON stdin: {dbus, op: playpause|play|pause|stop|next|previous}."""
import json
import subprocess
import sys


def main():
    if len(sys.argv) > 1 and sys.argv[1].strip().startswith("{"):
        data = json.loads(sys.argv[1])
    else:
        data = json.load(sys.stdin)
    dbus = data.get("dbus", "")
    op = data.get("op", "playpause")
    if not dbus:
        print(json.dumps({"ok": False}))
        return
    flag = {
        "playpause": "play-pause",
        "play": "play",
        "pause": "pause",
        "stop": "stop",
        "next": "next",
        "previous": "previous",
    }.get(op, "play-pause")
    try:
        subprocess.check_call(
            ["playerctl", "-p", dbus, flag],
            stderr=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
        )
        print(json.dumps({"ok": True}))
    except (subprocess.CalledProcessError, FileNotFoundError):
        print(json.dumps({"ok": False}))


if __name__ == "__main__":
    main()