#!/usr/bin/env python3
"""Compact system lines for samaelv2 lock (no pokemon / full fastfetch)."""
import json
import os
import platform
import re
import subprocess
import sys


def _run(cmd: list[str], timeout: float = 4.0) -> str:
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return (r.stdout or "").strip()
    except (subprocess.TimeoutExpired, OSError):
        return ""


def main() -> None:
    lines: list[str] = []

    # OS
    if os.path.exists("/etc/os-release"):
        with open("/etc/os-release", encoding="utf-8", errors="replace") as f:
            text = f.read()
        m = re.search(r'^PRETTY_NAME="(.+)"', text, re.M)
        lines.append("OS: " + (m.group(1) if m else platform.system()))
    else:
        lines.append("OS: " + platform.system())

    uname = platform.uname()
    lines.append("Kernel: " + uname.release)
    lines.append("WM: Hyprland")

    cpu = _run(["bash", "-c", "grep -m1 'model name' /proc/cpuinfo | cut -d: -f2"])
    if cpu:
        cpu = re.sub(r"\s+", " ", cpu).strip()
        if len(cpu) > 52:
            cpu = cpu[:49] + "…"
        lines.append("CPU: " + cpu)

    gpu = ""
    if _run(["bash", "-c", "command -v nvidia-smi"]):
        gpu = _run(
            ["nvidia-smi", "--query-gpu=name", "--format=csv,noheader"],
            timeout=3,
        ).split("\n")[0].strip()
    if not gpu:
        gpu = _run(
            [
                "bash",
                "-c",
                "lspci 2>/dev/null | grep -iE 'vga|3d' | head -1 | sed 's/.*: //'",
            ],
            timeout=3,
        )
    if gpu:
        if len(gpu) > 48:
            gpu = gpu[:45] + "…"
        lines.append("GPU: " + gpu)

    print(json.dumps({"lines": lines}, ensure_ascii=False))


if __name__ == "__main__":
    main()