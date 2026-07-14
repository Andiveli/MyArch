#!/usr/bin/env python3
"""Write calendar-secrets.json from JSON on stdin. Path: argv[1] or SAMAELV2_CALENDAR_SECRETS."""
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
        dest = os.environ.get("SAMAELV2_CALENDAR_SECRETS", "").strip()
    if not dest:
        dest = str(Path.home() / ".config" / "quickshell" / "samaelv2" / "calendar-secrets.json")
    try:
        data = json.loads(raw) if raw.strip() else {"icalUrls": []}
    except json.JSONDecodeError as e:
        print(json.dumps({"ok": False, "error": f"invalid json: {e}"}))
        sys.exit(1)

    urls = data.get("icalUrls", [])
    if not isinstance(urls, list):
        urls = []
    clean = []
    for u in urls:
        s = str(u).strip()
        if s and s not in clean:
            clean.append(s)

    out = {"icalUrls": clean}
    path = Path(dest).expanduser()
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(out, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    try:
        path.chmod(0o600)
    except OSError:
        pass
    print(json.dumps({"ok": True, "path": str(path), "count": len(clean)}))


if __name__ == "__main__":
    main()