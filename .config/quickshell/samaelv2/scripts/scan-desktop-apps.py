#!/usr/bin/env python3
"""Scan .desktop apps (same dirs as samael Notlight). JSON stdout for LauncherService."""
import json
import os
import re
import sys

DIRS = [
    os.path.expanduser("~/.local/share/applications"),
    "/usr/share/applications",
    "/usr/local/share/applications",
    "/var/lib/flatpak/exports/share/applications",
    os.path.expanduser("~/.local/share/flatpak/exports/share/applications"),
]
ICON_DIRS = [
    os.path.expanduser("~/.local/share/icons/hicolor/48x48/apps"),
    os.path.expanduser("~/.local/share/icons/hicolor/64x64/apps"),
    os.path.expanduser("~/.local/share/icons/hicolor/scalable/apps"),
    "/usr/share/icons/hicolor/48x48/apps",
    "/usr/share/icons/hicolor/64x64/apps",
    "/usr/share/icons/hicolor/scalable/apps",
    "/usr/share/icons/hicolor/32x32/apps",
    "/usr/share/icons/Adwaita/48x48/apps",
    "/usr/share/icons/Adwaita/scalable/apps",
    "/usr/share/pixmaps",
]
EXTS = (".png", ".svg", ".xpm")


def resolve_icon(name: str) -> str:
    if not name:
        return ""
    if name.startswith("/"):
        return name if os.path.isfile(name) else ""
    for d in ICON_DIRS:
        if not os.path.isdir(d):
            continue
        for e in EXTS:
            p = os.path.join(d, name + e)
            if os.path.isfile(p):
                return p
        p = os.path.join(d, name)
        if os.path.isfile(p):
            return p
    return ""


def parse_desktop(path: str) -> dict | None:
    entry = {
        "desktopId": os.path.basename(path),
        "name": "",
        "exec": "",
        "icon": "",
        "iconPath": "",
        "comment": "",
        "categories": "",
        "terminal": False,
    }
    in_desktop = False
    skip = False
    try:
        with open(path, "r", errors="ignore") as f:
            for line in f:
                line = line.strip()
                if line.startswith("["):
                    in_desktop = line == "[Desktop Entry]"
                    continue
                if not in_desktop or not line or line.startswith("#"):
                    continue
                if "=" not in line:
                    continue
                k, v = line.split("=", 1)
                k, v = k.strip(), v.strip()
                if k == "Type" and v != "Application":
                    skip = True
                    break
                if k == "NoDisplay" and v == "true":
                    skip = True
                    break
                if k == "Name" and not entry["name"]:
                    entry["name"] = v
                elif k == "Exec":
                    entry["exec"] = v
                elif k == "Icon":
                    entry["icon"] = v
                elif k == "Comment":
                    entry["comment"] = v
                elif k == "Categories":
                    entry["categories"] = v
                elif k == "Terminal" and v == "true":
                    entry["terminal"] = True
    except OSError:
        return None
    if skip or not entry["name"] or not entry["exec"]:
        return None
    entry["exec"] = re.sub(
        r"%[fFuUdDnNickvm]",
        "",
        entry["exec"].replace("%%", "\x00"),
    ).replace("\x00", "%").strip()
    entry["iconPath"] = resolve_icon(entry["icon"])
    return entry


def main() -> int:
    seen: set[str] = set()
    result: list[dict] = []
    for d in DIRS:
        if not os.path.isdir(d):
            continue
        for f in sorted(os.listdir(d)):
            if not f.endswith(".desktop") or f in seen:
                continue
            seen.add(f)
            parsed = parse_desktop(os.path.join(d, f))
            if parsed:
                result.append(parsed)
    result.sort(key=lambda x: x["name"].lower())
    json.dump(result, sys.stdout, ensure_ascii=False)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())