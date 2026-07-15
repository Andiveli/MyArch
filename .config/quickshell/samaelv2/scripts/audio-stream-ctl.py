#!/usr/bin/env python3
"""Control one sink-input: move, volume, mute. JSON argv or stdin."""
import json
import re
import subprocess
import sys


def run(cmd):
    try:
        subprocess.check_call(cmd, stderr=subprocess.DEVNULL)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False


def pactl_list_sink_inputs():
    try:
        return subprocess.check_output(
            ["pactl", "list", "sink-inputs"], text=True, stderr=subprocess.DEVNULL
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        return ""


def sink_input_muted(sid):
    raw = pactl_list_sink_inputs()
    if not raw:
        return False
    for chunk in re.split(r"(?m)^Sink Input #", raw):
        chunk = chunk.strip()
        if not chunk.startswith(str(sid)):
            continue
        m = re.search(r"Mute:\s*(\w+)", chunk)
        if m:
            return m.group(1).lower() in ("yes", "1", "true")
        return False
    return False


def load_payload():
    if len(sys.argv) > 1 and sys.argv[1].strip().startswith("{"):
        return json.loads(sys.argv[1])
    return json.load(sys.stdin)


def main():
    data = load_payload()
    op = data.get("op", "")
    sid = str(data.get("streamId", ""))
    if not sid:
        print(json.dumps({"ok": False, "error": "no streamId"}))
        return
    ok = False
    if op == "move":
        ok = run(["pactl", "move-sink-input", sid, str(data.get("sinkId", ""))])
        if ok:
            run(["pactl", "suspend-sink-input", sid, "0"])
    elif op == "volume":
        v = int(data.get("volume", 50))
        v = max(0, min(100, v))
        ok = run(["pactl", "set-sink-input-volume", sid, f"{v}%"])
    elif op == "mute":
        want = bool(data.get("mute"))
        ok = run(["pactl", "set-sink-input-mute", sid, "1" if want else "0"])
    elif op == "mute_toggle":
        cur = sink_input_muted(sid)
        ok = run(["pactl", "set-sink-input-mute", sid, "0" if cur else "1"])
    else:
        print(json.dumps({"ok": False, "error": "unknown op"}))
        return
    print(json.dumps({"ok": ok, "muted": sink_input_muted(sid) if ok else None}))


if __name__ == "__main__":
    main()