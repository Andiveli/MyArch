#!/usr/bin/env python3
"""Print config.json contents to stdout (for settings draft refresh)."""
from __future__ import annotations

import sys
from pathlib import Path


def main() -> None:
    dest = (sys.argv[1] if len(sys.argv) > 1 else "").strip()
    if not dest:
        dest = str(Path.home() / ".config" / "quickshell" / "samaelv2" / "config.json")
    path = Path(dest).expanduser()
    if not path.is_file():
        sys.exit(1)
    sys.stdout.write(path.read_text(encoding="utf-8"))


if __name__ == "__main__":
    main()