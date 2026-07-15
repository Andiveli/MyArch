#!/usr/bin/env python3
"""Pick pulse monitor source for cava: sink that has the most active playback streams."""
import re
import subprocess
import sys


def run(cmd):
    try:
        return subprocess.check_output(cmd, text=True, stderr=subprocess.DEVNULL)
    except (subprocess.CalledProcessError, FileNotFoundError):
        return ""


def sink_names():
    names = {}
    for line in run(["pactl", "list", "short", "sinks"]).strip().splitlines():
        parts = line.split("\t")
        if len(parts) >= 2:
            names[parts[0]] = parts[1]
    return names


def dominant_sink_id():
    raw = run(["pactl", "list", "sink-inputs"])
    if not raw:
        return ""
    counts = {}
    for chunk in re.split(r"(?m)^Sink Input #", raw):
        chunk = chunk.strip()
        if not chunk:
            continue
        cork = re.search(r"Corked:\s*(\w+)", chunk)
        if cork and cork.group(1).lower() in ("yes", "1", "true"):
            continue
        sink_m = re.search(r"Sink:\s*(\d+)", chunk)
        if sink_m:
            sid = sink_m.group(1)
            counts[sid] = counts.get(sid, 0) + 1
    if not counts:
        return ""
    # Most streams wins; tie → lower sink id (stable, often built-in < BT)
    return min(counts.keys(), key=lambda k: (-counts[k], int(k) if k.isdigit() else 0))


def default_monitor():
    name = run(["pactl", "get-default-sink"]).strip()
    if name:
        return name + ".monitor"
    return "auto"


def pick_monitor():
    names = sink_names()
    sid = dominant_sink_id()
    if sid and sid in names:
        return names[sid] + ".monitor"
    return default_monitor()


def write_cava_config(path, source):
    body = (
        "[general]\nframerate=30\nbars=24\n\n[input]\nmethod=pulse\nsource="
        + source
        + "\n\n[output]\nmethod=raw\nraw_target=/dev/stdout\ndata_format=ascii\nascii_max_range=7\n"
    )
    with open(path, "w", encoding="utf-8") as f:
        f.write(body)


def main():
    source = pick_monitor()
    if len(sys.argv) > 1:
        write_cava_config(sys.argv[1], source)
    print(source)


if __name__ == "__main__":
    main()