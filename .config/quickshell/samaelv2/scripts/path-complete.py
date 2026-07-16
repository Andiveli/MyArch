#!/usr/bin/env python3
"""Directory name completion for settings path fields. JSON stdout."""
from __future__ import annotations

import json
import os
import sys


def expand_partial(partial: str) -> str:
    p = (partial or "").strip()
    if not p:
        return os.path.expanduser("~")
    if p == "~":
        return os.path.expanduser("~")
    if p.startswith("~/"):
        return os.path.expanduser(p)
    if p.startswith("~"):
        return os.path.expanduser(p)
    return os.path.abspath(p)


def parent_and_prefix(partial: str) -> tuple[str, str]:
    p = (partial or "").strip()
    if not p:
        home = os.path.expanduser("~")
        return home, ""
    if p.endswith("/") or p.endswith(os.sep):
        base = expand_partial(p.rstrip("/"))
        if os.path.isdir(base):
            return base, ""
        return os.path.dirname(base) or "/", ""
    base = expand_partial(p)
    if os.path.isdir(base):
        return base, ""
    parent = os.path.dirname(base)
    if not parent:
        parent = "/"
    leaf = os.path.basename(base)
    return parent, leaf


def list_dirs(parent: str, prefix: str, limit: int = 24) -> list[str]:
    out: list[str] = []
    if not os.path.isdir(parent):
        return out
    try:
        names = sorted(os.listdir(parent))
    except OSError:
        return out
    pl = prefix.lower()
    for name in names:
        if name.startswith("."):
            continue
        full = os.path.join(parent, name)
        if not os.path.isdir(full):
            continue
        if pl and not name.lower().startswith(pl):
            continue
        out.append(name)
        if len(out) >= limit:
            break
    return out


def to_display_path(parent: str, name: str, partial: str) -> str:
    full = os.path.join(parent, name)
    home = os.path.expanduser("~")
    if partial.strip().startswith("~") or parent.startswith(home):
        if full.startswith(home):
            return "~" + full[len(home) :]
    return full


def main() -> int:
    partial = sys.argv[1] if len(sys.argv) > 1 else ""
    parent, prefix = parent_and_prefix(partial)
    names = list_dirs(parent, prefix)
    suggestions = [to_display_path(parent, n, partial) for n in names]
    common = os.path.commonprefix(suggestions) if suggestions else ""
    if common and len(suggestions) > 1 and len(common) > len(partial):
        completion = common
    elif len(suggestions) == 1:
        completion = suggestions[0]
        if not completion.endswith("/"):
            completion += "/"
    else:
        completion = ""
    print(
        json.dumps(
            {
                "suggestions": suggestions,
                "completion": completion,
                "parent": parent,
                "prefix": prefix,
            },
            ensure_ascii=False,
        )
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())