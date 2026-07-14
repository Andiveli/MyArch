#!/usr/bin/env python3
"""Fetch Google Calendar (or any) iCal feeds and emit JSON for samaelv2."""
from __future__ import annotations

import json
import os
import re
import sys
import urllib.error
import urllib.request
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any

TIMEOUT = 25
MAX_EVENTS = 800
CACHE_DIR = Path.home() / ".cache" / "samaelv2" / "calendar"
CACHE_FILE = CACHE_DIR / "events.json"


def _unfold(lines: list[str]) -> list[str]:
    out: list[str] = []
    for line in lines:
        if line.startswith((" ", "\t")) and out:
            out[-1] += line[1:]
        else:
            out.append(line.rstrip("\r\n"))
    return out


def _parse_ical_dt(value: str, tzid: str | None = None) -> tuple[str, str, bool]:
    """Return (dateKey YYYY-MM-DD, time HH:MM or '', allDay)."""
    v = value.strip()
    if not v:
        return "", "", True
    if len(v) == 8 and v.isdigit():
        return f"{v[0:4]}-{v[4:6]}-{v[6:8]}", "", True
    if "T" in v:
        date_part, time_part = v.split("T", 1)
        time_part = time_part.replace("Z", "")
        for suf in ("Z",):
            time_part = time_part.replace(suf, "")
        if len(date_part) == 8 and date_part.isdigit():
            dk = f"{date_part[0:4]}-{date_part[4:6]}-{date_part[6:8]}"
            tp = re.sub(r"[^0-9]", "", time_part)[:6]
            if len(tp) >= 4:
                hh, mm = tp[0:2], tp[2:4]
                return dk, f"{hh}:{mm}", False
            return dk, "", False
    return "", "", True


def _flush_component(cur: dict[str, str], uid: int, kind: str) -> dict[str, Any] | None:
    if not cur.get("SUMMARY") and not cur.get("DTSTART") and not cur.get("DUE"):
        return None
    start_raw = cur.get("DTSTART") or cur.get("DUE") or ""
    end_raw = cur.get("DTEND", "") or start_raw
    dk, tm, all_day = _parse_ical_dt(start_raw)
    edk, etm, _ = _parse_ical_dt(end_raw)
    if not dk:
        return None
    if not edk:
        edk = dk
    if all_day and edk > dk:
        try:
            y, m, d = int(edk[0:4]), int(edk[5:7]), int(edk[8:10])
            dt = datetime(y, m, d) - timedelta(days=1)
            edk = dt.strftime("%Y-%m-%d")
        except ValueError:
            edk = dk
    text = (cur.get("SUMMARY") or "(no title)").strip()
    if kind == "VTODO" and not text.startswith("☐") and not text.startswith("✓"):
        text = "☐ " + text
    desc = (cur.get("DESCRIPTION") or "").strip().replace("\\n", "\n")[:400]
    loc = (cur.get("LOCATION") or "").strip().replace("\\,", ",").replace("\\n", " ")[:280]
    return {
        "id": cur.get("UID") or f"{kind.lower()}-{uid}",
        "date": dk,
        "endDate": edk if edk != dk else "",
        "time": tm,
        "endTime": etm if etm != tm else "",
        "text": text,
        "location": loc,
        "description": desc,
        "allDay": all_day or kind == "VTODO",
        "kind": "task" if kind == "VTODO" else "event",
    }


def _parse_events(ics: str) -> list[dict[str, Any]]:
    lines = _unfold(ics.splitlines())
    events: list[dict[str, Any]] = []
    in_block = False
    block_kind = ""
    cur: dict[str, str] = {}
    uid = 0

    for line in lines:
        if line.startswith("BEGIN:"):
            kind = line[6:].strip().upper()
            if kind in ("VEVENT", "VTODO"):
                in_block = True
                block_kind = kind
                cur = {}
            continue
        if line.startswith("END:"):
            kind = line[4:].strip().upper()
            if in_block and kind == block_kind:
                uid += 1
                row = _flush_component(cur, uid, block_kind)
                if row:
                    events.append(row)
            in_block = False
            block_kind = ""
            cur = {}
            continue
        if not in_block or ":" not in line:
            continue
        key, _, val = line.partition(":")
        key = key.split(";", 1)[0].upper()
        if key in ("DTSTART", "DTEND", "DUE", "SUMMARY", "DESCRIPTION", "LOCATION", "UID", "COMPLETED"):
            cur[key] = val.strip()

    return events[:MAX_EVENTS]


def fetch_url(url: str) -> str:
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "samaelv2-calendar/1.0"},
    )
    with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
        return resp.read().decode("utf-8", errors="replace")


def _dedupe_urls(urls: list[str]) -> list[str]:
    out: list[str] = []
    seen: set[str] = set()
    for u in urls:
        s = str(u).strip()
        if s and s not in seen:
            seen.add(s)
            out.append(s)
    return out


def collect_ical_urls(config_path: Path | None) -> list[str]:
    """Secrets file + env only — never read ical URLs from config.json (safe for git)."""
    urls: list[str] = []

    secrets_path = os.environ.get("SAMAELV2_CALENDAR_SECRETS", "").strip()
    if not secrets_path and config_path:
        secrets_path = str(config_path.parent / "calendar-secrets.json")
    if secrets_path:
        p = Path(secrets_path).expanduser()
        if p.is_file():
            try:
                data = json.loads(p.read_text(encoding="utf-8"))
                raw = data.get("icalUrls", [])
                if isinstance(raw, list):
                    urls.extend(str(u).strip() for u in raw if str(u).strip())
            except (json.JSONDecodeError, OSError):
                pass

    env_urls = os.environ.get("SAMAELV2_CALENDAR_ICAL_URLS", "").strip()
    if env_urls:
        for part in env_urls.replace("\n", ",").split(","):
            part = part.strip()
            if part:
                urls.append(part)

    return _dedupe_urls(urls)


def main() -> None:
    config_path = Path(sys.argv[1]) if len(sys.argv) > 1 else None
    urls = collect_ical_urls(config_path)

    merged: list[dict[str, Any]] = []
    errors: list[str] = []
    seen: set[str] = set()

    for url in urls:
        try:
            ics = fetch_url(url)
            for ev in _parse_events(ics):
                sig = f"{ev.get('date')}|{ev.get('time')}|{ev.get('text')}"
                if sig in seen:
                    continue
                seen.add(sig)
                merged.append(ev)
        except (urllib.error.URLError, TimeoutError, OSError) as e:
            errors.append(f"{url[:48]}…: {e}")

    merged.sort(key=lambda e: (e.get("date") or "", e.get("time") or ""))

    payload = {
        "fetchedAt": datetime.now(timezone.utc).isoformat(),
        "events": merged,
        "errors": errors,
        "configured": len(urls) > 0,
    }

    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    CACHE_FILE.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")
    print(json.dumps(payload, ensure_ascii=False))


if __name__ == "__main__":
    main()