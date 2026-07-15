#!/usr/bin/env python3
"""Apply per-app sink rules from JSON stdin or file. Uses pactl move-sink-input."""
import json
import re
import subprocess
import sys


def run(cmd):
    try:
        subprocess.run(cmd, check=False, stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
    except FileNotFoundError:
        pass


def stream_props(sid):
    try:
        out = subprocess.check_output(
            ["pactl", "list", "sink-inputs"],
            text=True,
            stderr=subprocess.DEVNULL,
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        return {}
    needle = f"Sink Input #{sid}"
    idx = out.find(needle)
    if idx < 0:
        return {}
    end = out.find("\nSink Input #", idx + 1)
    chunk = out[idx:end if end >= 0 else len(out)]
    props = {}
    for line in chunk.splitlines():
        m = re.match(r"\s+([a-zA-Z0-9_.]+) = \"(.*)\"", line)
        if m:
            props[m.group(1)] = m.group(2)
    return props


def list_stream_ids():
    try:
        out = subprocess.check_output(
            ["pactl", "list", "short", "sink-inputs"],
            text=True,
            stderr=subprocess.DEVNULL,
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        return []
    ids = []
    for line in out.strip().splitlines():
        parts = line.split("\t")
        if parts:
            ids.append(parts[0])
    return ids


def match_rule(props, rule):
    kind = rule.get("matchKind") or "application.process.binary"
    needle = (rule.get("match") or "").strip().lower()
    if not needle:
        return False
    val = (props.get(kind) or "").lower()
    if not val:
        return False
    mode = rule.get("matchMode") or "contains"
    if mode == "equals":
        return val == needle
    return needle in val


def main():
    if len(sys.argv) > 1 and sys.argv[1] != "-":
        with open(sys.argv[1], encoding="utf-8") as f:
            cfg = json.load(f)
        rules = (cfg.get("audio") or {}).get("routingRules") or []
    else:
        data = json.load(sys.stdin)
        rules = data.get("rules") or []
    if not rules:
        print(json.dumps({"ok": True, "moved": 0}))
        return
    moved = 0
    for sid in list_stream_ids():
        props = stream_props(sid)
        if not props:
            continue
        for rule in rules:
            if not rule.get("enabled", True):
                continue
            sink = str(rule.get("sinkId") or rule.get("sink") or "").strip()
            if not sink:
                continue
            if match_rule(props, rule):
                run(["pactl", "move-sink-input", sid, sink])
                run(["pactl", "suspend-sink-input", sid, "0"])
                moved += 1
                break
    print(json.dumps({"ok": True, "moved": moved}))


if __name__ == "__main__":
    main()