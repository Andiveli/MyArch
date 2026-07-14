#!/usr/bin/env python3
"""Write config.json from JSON on stdin or --json payload. Path: argv dest or shell default."""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path


def main() -> None:
    raw: str
    dest: str
    if len(sys.argv) > 3 and sys.argv[1] == "--json":
        raw = sys.argv[2]
        dest = sys.argv[3].strip()
    else:
        raw = sys.stdin.read()
        dest = (sys.argv[1] if len(sys.argv) > 1 else "").strip()
    if not dest:
        dest = os.environ.get("SAMAELV2_CONFIG", "").strip()
    if not dest:
        dest = str(Path.home() / ".config" / "quickshell" / "samaelv2" / "config.json")
    try:
        data = json.loads(raw) if raw.strip() else {}
    except json.JSONDecodeError as e:
        print(json.dumps({"ok": False, "error": f"invalid json: {e}"}))
        sys.exit(1)

    if not isinstance(data, dict):
        print(json.dumps({"ok": False, "error": "root must be a JSON object"}))
        sys.exit(1)

    path = Path(dest).expanduser()
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({"ok": True, "path": str(path)}))


if __name__ == "__main__":
    main()