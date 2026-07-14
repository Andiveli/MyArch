#!/usr/bin/env python3
"""Fast home file search for launcher /f mode. JSON array stdout."""
import json
import os
import shutil
import subprocess
import sys

HOME = os.path.expanduser("~")
MAX = 48
SKIP_NAMES = {
    ".git",
    "node_modules",
    ".cache",
    ".npm",
    ".cargo",
    ".venv",
    "venv",
    "__pycache__",
    "Trash",
}


def _skip_dir(name: str) -> bool:
    return name in SKIP_NAMES


def _fd(query: str) -> list[dict]:
    q = (query or "").strip()
    if not q:
        return []
    # -F: literal match so dots in extensions (file.pdf) are not regex wildcards
    cmd = [
        "fd",
        "-F",
        "--type",
        "f",
        "--type",
        "d",
        "--max-results",
        str(MAX),
        "--hidden",
        "--no-ignore-vcs",
        "-i",
        q,
        HOME,
    ]
    try:
        out = subprocess.check_output(cmd, stderr=subprocess.DEVNULL, text=True, timeout=8)
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired, FileNotFoundError):
        return []
    rows = []
    for line in out.splitlines():
        p = line.strip()
        if not p or not os.path.exists(p):
            continue
        rows.append(
            {
                "path": p,
                "name": os.path.basename(p) or p,
                "isDir": os.path.isdir(p),
            }
        )
        if len(rows) >= MAX:
            break
    return rows


def _find_fallback(query: str) -> list[dict]:
    q = (query or "").strip().lower()
    if not q:
        return []
    rows = []
    home_len = len(HOME.rstrip(os.sep))
    for root, dirs, files in os.walk(HOME):
        rel = root[home_len:].lstrip(os.sep)
        depth = 0 if not rel else rel.count(os.sep) + 1
        if depth > 8:
            dirs[:] = []
            continue
        dirs[:] = [d for d in dirs if not _skip_dir(d)]
        for name in files + dirs:
            low = name.lower()
            if q not in low and q not in root.lower():
                continue
            p = os.path.join(root, name)
            rows.append(
                {
                    "path": p,
                    "name": name,
                    "isDir": os.path.isdir(p),
                }
            )
            if len(rows) >= MAX:
                return rows
    return rows


def _direct_hit(query: str) -> dict | None:
    q = (query or "").strip()
    if not q:
        return None
    if os.path.isabs(q) and os.path.exists(q):
        return {"path": q, "name": os.path.basename(q) or q, "isDir": os.path.isdir(q)}
    p = os.path.join(HOME, q)
    if os.path.exists(p):
        return {"path": p, "name": os.path.basename(p) or q, "isDir": os.path.isdir(p)}
    return None


def main() -> None:
    query = sys.argv[1] if len(sys.argv) > 1 else ""
    rows: list[dict] = []
    hit = _direct_hit(query)
    if hit:
        rows.append(hit)
    if shutil.which("fd"):
        for row in _fd(query):
            if row["path"] not in {r["path"] for r in rows}:
                rows.append(row)
            if len(rows) >= MAX:
                break
    else:
        for row in _find_fallback(query):
            if row["path"] not in {r["path"] for r in rows}:
                rows.append(row)
            if len(rows) >= MAX:
                break
    print(json.dumps(rows[:MAX], ensure_ascii=False))


if __name__ == "__main__":
    main()