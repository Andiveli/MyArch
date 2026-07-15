#!/usr/bin/env python3
"""List PipeWire/Pulse sinks and playback streams (sink-inputs) as JSON for samaelv2 audio settings."""
import json
import re
import subprocess
import sys


def run(cmd):
    try:
        return subprocess.check_output(cmd, text=True, stderr=subprocess.DEVNULL)
    except (subprocess.CalledProcessError, FileNotFoundError):
        return ""


def list_sinks():
    sinks = []
    for line in run(["pactl", "list", "short", "sinks"]).strip().splitlines():
        parts = line.split("\t")
        if len(parts) < 2:
            continue
        sid, name = parts[0], parts[1]
        desc = name
        detail = run(["pactl", "list", "sinks"])
        block = _block_for_name(detail, name)
        if block:
            m = re.search(r"Description:\s*(.+)", block)
            if m:
                desc = m.group(1).strip()
        sinks.append({"id": sid, "name": name, "description": desc})
    return sinks


def _block_for_name(text, name):
    needle = f"Name: {name}"
    idx = text.find(needle)
    if idx < 0:
        return ""
    start = text.rfind("\nSink #", 0, idx)
    if start < 0:
        start = text.rfind("Sink #", 0, idx)
    end = text.find("\nSink #", idx + 1)
    if end < 0:
        end = len(text)
    return text[start:end]


def list_streams():
    streams = []
    raw = run(["pactl", "list", "sink-inputs"])
    if not raw:
        return streams
    # First entry has no leading newline — split on line start, not only "\nSink Input #"
    chunks = re.split(r"(?m)^Sink Input #", raw)
    for chunk in chunks:
        chunk = chunk.strip()
        if not chunk:
            continue
        sid_m = re.match(r"(\d+)", chunk)
        if not sid_m:
            continue
        sid = sid_m.group(1)
        props = {}
        for key in (
            "application.name",
            "application.process.binary",
            "application.process.id",
            "media.name",
            "node.name",
        ):
            m = re.search(rf"{re.escape(key)} = \"([^\"]*)\"", chunk)
            if m:
                props[key] = m.group(1)
        sink_m = re.search(r"Sink:\s*(\d+)", chunk)
        sink_id = sink_m.group(1) if sink_m else ""
        cork_m = re.search(r"Corked:\s*(\w+)", chunk)
        corked = cork_m and cork_m.group(1).lower() in ("yes", "1", "true")
        mute_m = re.search(r"Mute:\s*(\w+)", chunk)
        muted = mute_m and mute_m.group(1).lower() in ("yes", "1", "true")
        vol_pct = 100
        vol_m = re.search(r"Volume:.*?(\d+)%", chunk)
        if vol_m:
            vol_pct = int(vol_m.group(1))
        else:
            fv = re.search(r"Volume:.*?(\d+)\s*/\s*(\d+)", chunk)
            if fv:
                a, b = int(fv.group(1)), int(fv.group(2))
                if b > 0:
                    vol_pct = min(100, max(0, int(round(100 * a / b))))
        label = props.get("application.name") or props.get("media.name") or props.get(
            "application.process.binary", "?"
        )
        media = props.get("media.name") or ""
        binary = props.get("application.process.binary") or ""
        streams.append(
            {
                "id": sid,
                "sinkId": sink_id,
                "label": label,
                "mediaTitle": media,
                "binary": binary,
                "volume": vol_pct,
                "muted": muted,
                "corked": corked,
                "properties": props,
            }
        )
    streams.sort(key=lambda s: (s.get("corked", False), s.get("label", "")))
    return streams


def main():
    print(
        json.dumps(
            {"sinks": list_sinks(), "streams": list_streams()},
            ensure_ascii=False,
        )
    )


if __name__ == "__main__":
    main()