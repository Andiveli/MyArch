#!/usr/bin/env python3
"""samaelv2 screen record — gpu-screen-recorder (Caelestia-style), no caelestia CLI."""

from __future__ import annotations

import json
import os
import re
import shutil
import signal
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path

RECORDER = "gpu-screen-recorder"
STATE_DIR = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp")) / "samaelv2-record"
STAGING = STATE_DIR / "staging.mp4"
PID_FILE = STATE_DIR / "recorder.pid"
PAUSED_FILE = STATE_DIR / "paused"
LAST_EXIT_FILE = STATE_DIR / "last_exit.json"
MIN_SAVE_BYTES = 4096


def _home() -> Path:
    return Path(os.environ.get("HOME", "/"))


def _config_path() -> Path:
    return _home() / ".config" / "quickshell" / "samaelv2" / "config.json"


def load_record_cfg() -> dict:
    p = _config_path()
    out = {
        "saveDir": str(_home() / "Videos"),
        "includeSystemAudio": True,
        "includeMic": False,
        "mode": "monitor",
        "monitor": "",
        "windowAddress": "",
        "extraArgs": [],
    }
    if not p.is_file():
        return out
    try:
        raw = json.loads(p.read_text(encoding="utf-8"))
        rec = raw.get("record") or {}
        if rec.get("saveDir"):
            out["saveDir"] = str(rec["saveDir"]).replace("~", str(_home()))
        out["includeSystemAudio"] = rec.get("includeSystemAudio", True)
        out["includeMic"] = rec.get("includeMic", False)
        out["mode"] = rec.get("mode") or "monitor"
        out["monitor"] = rec.get("monitor") or ""
        out["windowAddress"] = rec.get("windowAddress") or ""
        if isinstance(rec.get("extraArgs"), list):
            out["extraArgs"] = [str(x) for x in rec["extraArgs"]]
    except (json.JSONDecodeError, OSError):
        pass
    return out


def hypr_monitors() -> list:
    try:
        r = subprocess.run(
            ["hyprctl", "monitors", "-j"],
            capture_output=True,
            text=True,
            timeout=5,
        )
        if r.returncode != 0:
            return []
        return json.loads(r.stdout or "[]")
    except (subprocess.TimeoutExpired, json.JSONDecodeError, FileNotFoundError):
        return []


def hypr_clients() -> list:
    try:
        r = subprocess.run(
            ["hyprctl", "clients", "-j"],
            capture_output=True,
            text=True,
            timeout=5,
        )
        if r.returncode != 0:
            return []
        return json.loads(r.stdout or "[]")
    except (subprocess.TimeoutExpired, json.JSONDecodeError, FileNotFoundError):
        return []


def intersects(a: tuple, b: tuple) -> bool:
    ax, ay, aw, ah = a
    bx, by, bw, bh = b
    return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by


def proc_gone(pid: int) -> bool:
    try:
        os.kill(pid, 0)
        return False
    except OSError:
        return True


def read_last_exit() -> str:
    if not LAST_EXIT_FILE.is_file():
        return ""
    try:
        data = json.loads(LAST_EXIT_FILE.read_text(encoding="utf-8"))
        return str(data.get("message") or data.get("reason") or "")
    except (json.JSONDecodeError, OSError):
        return ""


def reconcile_dead_recorder() -> None:
    """Recorder died without record-ctl stop — clean pid and record why."""
    if not PID_FILE.is_file():
        return
    try:
        pid = int(PID_FILE.read_text().strip())
        os.kill(pid, 0)
        return
    except (OSError, ValueError):
        pass
    size = STAGING.stat().st_size if STAGING.is_file() else 0
    msg = "Recording stopped unexpectedly."
    if size < MIN_SAVE_BYTES:
        msg += " No usable file (recorder exited too soon — reload shell and try again)."
    else:
        msg += f" Staging had {size} bytes but was not saved — press Stop before closing."
    LAST_EXIT_FILE.write_text(
        json.dumps({"message": msg, "stagingBytes": size}, ensure_ascii=False),
        encoding="utf-8",
    )
    PID_FILE.unlink(missing_ok=True)
    PAUSED_FILE.unlink(missing_ok=True)


def recorder_pid() -> int | None:
    """Only trust our pid file — avoid pidof picking unrelated recorder instances."""
    if not PID_FILE.is_file():
        return None
    try:
        pid = int(PID_FILE.read_text().strip())
        os.kill(pid, 0)
        return pid
    except (OSError, ValueError):
        PID_FILE.unlink(missing_ok=True)
    return None


def is_paused() -> bool:
    return PAUSED_FILE.is_file()


def wpctl_volume_mute(target: str) -> dict:
    """target: sink | source (default audio)."""
    node = "@DEFAULT_AUDIO_SINK@" if target == "sink" else "@DEFAULT_AUDIO_SOURCE@"
    vol = subprocess.run(["wpctl", "get-volume", node], capture_output=True, text=True, timeout=3)
    line = (vol.stdout or "").strip()
    muted = "[MUTED]" in line
    pct = 0.0
    m = re.search(r"([0-9]*\.?[0-9]+)", line)
    if m:
        pct = min(100.0, max(0.0, float(m.group(1)) * 100.0))
    return {"volume": round(pct), "muted": muted}


def cmd_status() -> int:
    reconcile_dead_recorder()
    cfg = load_record_cfg()
    pid = recorder_pid()
    monitors = hypr_monitors()
    clients = hypr_clients()
    audio_sink = wpctl_volume_mute("sink")
    audio_source = wpctl_volume_mute("source")
    rec = shutil.which(RECORDER) or ""
    out = {
        "running": pid is not None,
        "paused": is_paused() if pid else False,
        "recorderInstalled": bool(rec),
        "recorderPath": rec,
        "config": cfg,
        "monitors": [
            {
                "name": m.get("name", ""),
                "description": m.get("description", m.get("name", "")),
                "focused": bool(m.get("focused")),
                "width": m.get("width", 0),
                "height": m.get("height", 0),
            }
            for m in monitors
        ],
        "windows": [
            {
                "address": c.get("address", ""),
                "title": c.get("title", ""),
                "class": c.get("class", ""),
                "x": c.get("at", [0, 0])[0] if isinstance(c.get("at"), list) else 0,
                "y": c.get("at", [0, 0])[1] if isinstance(c.get("at"), list) else 0,
                "width": c.get("size", [0, 0])[0] if isinstance(c.get("size"), list) else 0,
                "height": c.get("size", [0, 0])[1] if isinstance(c.get("size"), list) else 0,
            }
            for c in clients
            if c.get("mapped", True) and (c.get("title") or c.get("class"))
        ],
        "audioSink": audio_sink,
        "audioSource": audio_source,
        "lastError": read_last_exit() if pid is None else "",
    }
    print(json.dumps(out))
    return 0


def build_recorder_args(cfg: dict, region: str | None) -> list[str]:
    args = ["-w"]
    monitors = hypr_monitors()
    mode = cfg.get("mode") or "monitor"

    if mode == "region" or region:
        reg = region
        if not reg:
            r = subprocess.run(["slurp", "-f", "%wx%h+%x+%y"], capture_output=True, text=True)
            if r.returncode != 0:
                raise RuntimeError("region selection cancelled")
            reg = r.stdout.strip()
        args += ["region", "-region", reg]
        m = re.match(r"(\d+)x(\d+)\+(-?\d+)\+(-?\d+)", reg)
        if not m:
            raise ValueError(f"invalid region: {reg}")
        w, h, x, y = map(int, m.groups())
        max_rr = 60
        for mon in monitors:
            mx = mon.get("x", 0)
            my = mon.get("y", 0)
            mw = mon.get("width", 0)
            mh = mon.get("height", 0)
            if intersects((x, y, w, h), (mx, my, mw, mh)):
                max_rr = max(max_rr, round(mon.get("refreshRate", 60)))
        args += ["-f", str(max_rr)]
    elif mode == "window":
        addr = (cfg.get("windowAddress") or "").strip()
        if not addr:
            raise RuntimeError("no window selected")
        c = next((x for x in hypr_clients() if x.get("address") == addr), None)
        if not c:
            raise RuntimeError("window not found")
        at = c.get("at", [0, 0])
        sz = c.get("size", [0, 0])
        reg = f"{sz[0]}x{sz[1]}+{at[0]}+{at[1]}"
        args += ["region", "-region", reg]
        args += ["-f", "60"]
    else:
        name = (cfg.get("monitor") or "").strip()
        focused = next((m for m in monitors if m.get("focused")), None)
        pick = next((m for m in monitors if m.get("name") == name), None) if name else None
        mon = pick or focused or (monitors[0] if monitors else None)
        if not mon:
            raise RuntimeError("no monitor")
        args += [mon["name"], "-f", str(round(mon.get("refreshRate", 60)))]

    if cfg.get("includeSystemAudio"):
        args += ["-a", "default_output"]
    if cfg.get("includeMic"):
        args += ["-a", "default_input"]

    extra = cfg.get("extraArgs") or []
    if isinstance(extra, list):
        args += [str(x) for x in extra]
    return args


def cmd_start(region: str | None, force_slurp: bool = False) -> int:
    if recorder_pid():
        print(json.dumps({"ok": False, "error": "already recording"}))
        return 1
    if not shutil.which(RECORDER):
        print(json.dumps({"ok": False, "error": f"{RECORDER} not installed"}))
        return 1
    cfg = load_record_cfg()
    if force_slurp:
        cfg = dict(cfg)
        cfg["mode"] = "region"
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    STAGING.parent.mkdir(parents=True, exist_ok=True)
    try:
        args = build_recorder_args(cfg, region)
    except RuntimeError as e:
        print(json.dumps({"ok": False, "error": str(e)}))
        return 1
    except ValueError as e:
        print(json.dumps({"ok": False, "error": str(e)}))
        return 1

    STAGING.unlink(missing_ok=True)
    LAST_EXIT_FILE.unlink(missing_ok=True)

    cmd = [RECORDER, *args, "-o", str(STAGING)]
    # Never use stderr=PIPE without a drain thread — gsr logs heavily and dies when the pipe fills.
    proc = subprocess.Popen(
        cmd,
        start_new_session=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        env=os.environ.copy(),
    )
    time.sleep(0.55)
    if proc.poll() is not None:
        msg = f"recorder exited immediately (code {proc.returncode})"
        LAST_EXIT_FILE.write_text(json.dumps({"message": msg}), encoding="utf-8")
        print(json.dumps({"ok": False, "error": msg}))
        return 1
    PID_FILE.write_text(str(proc.pid))
    PAUSED_FILE.unlink(missing_ok=True)
    print(json.dumps({"ok": True}))
    return 0


def cmd_stop() -> int:
    pid = recorder_pid()
    if not pid:
        print(json.dumps({"ok": True, "path": ""}))
        return 0
    try:
        os.kill(pid, signal.SIGINT)
    except OSError:
        pass
    for _ in range(30):
        if proc_gone(pid):
            break
        time.sleep(0.1)
    if not proc_gone(pid):
        subprocess.run(["pkill", "-f", RECORDER], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    for _ in range(80):
        if proc_gone(pid):
            break
        time.sleep(0.1)
    time.sleep(0.35)

    cfg = load_record_cfg()
    dest_dir = Path(cfg["saveDir"]).expanduser()
    dest_dir.mkdir(parents=True, exist_ok=True)
    path = ""
    err = ""
    size = STAGING.stat().st_size if STAGING.is_file() else 0
    if STAGING.is_file() and size >= MIN_SAVE_BYTES:
        name = f"recording_{datetime.now().strftime('%Y%m%d_%H-%M-%S')}.mp4"
        final = dest_dir / name
        shutil.move(str(STAGING), str(final))
        path = str(final)
        LAST_EXIT_FILE.unlink(missing_ok=True)
    elif STAGING.is_file() and size > 0:
        err = f"Recording too small ({size} B) — not saved."
        LAST_EXIT_FILE.write_text(json.dumps({"message": err, "stagingBytes": size}), encoding="utf-8")
        STAGING.unlink(missing_ok=True)
    else:
        err = "No recording data — stop after a few seconds of capture."
        LAST_EXIT_FILE.write_text(json.dumps({"message": err}), encoding="utf-8")

    PID_FILE.unlink(missing_ok=True)
    PAUSED_FILE.unlink(missing_ok=True)
    out = {"ok": True, "path": path}
    if err:
        out["error"] = err
    print(json.dumps(out))
    return 0


def cmd_pause() -> int:
    if not recorder_pid():
        print(json.dumps({"ok": False, "error": "not recording"}))
        return 1
    subprocess.run(["pkill", "-USR2", "-f", RECORDER], stdout=subprocess.DEVNULL)
    if is_paused():
        PAUSED_FILE.unlink(missing_ok=True)
        paused = False
    else:
        PAUSED_FILE.touch()
        paused = True
    print(json.dumps({"ok": True, "paused": paused}))
    return 0


def cmd_audio(op: str, target: str, value: str | None) -> int:
    node = "@DEFAULT_AUDIO_SINK@" if target == "sink" else "@DEFAULT_AUDIO_SOURCE@"
    if op == "toggle-mute":
        subprocess.run(["wpctl", "set-mute", node, "toggle"], check=False)
    elif op == "set-volume" and value is not None:
        v = max(0, min(100, int(float(value))))
        subprocess.run(["wpctl", "set-volume", node, f"{v}%"], check=False)
    print(json.dumps({"ok": True}))
    return 0


def cmd_patch(patch_json: str) -> int:
    try:
        patch = json.loads(patch_json)
    except json.JSONDecodeError as e:
        print(json.dumps({"ok": False, "error": str(e)}))
        return 1
    if not isinstance(patch, dict):
        print(json.dumps({"ok": False, "error": "patch must be object"}))
        return 1
    p = _config_path()
    raw = {}
    if p.is_file():
        try:
            raw = json.loads(p.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            raw = {}
    rec = raw.get("record") or {}
    if not isinstance(rec, dict):
        rec = {}
    rec.update(patch)
    raw["record"] = rec
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(raw, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({"ok": True}))
    return 0


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: record-ctl.py status|start|stop|pause|audio|patch ...", file=sys.stderr)
        return 2
    op = sys.argv[1]
    if op == "status":
        return cmd_status()
    if op == "start":
        reg: str | None = None
        force_slurp = False
        if len(sys.argv) > 2:
            if sys.argv[2] == "slurp":
                force_slurp = True
            elif sys.argv[2] == "region" and len(sys.argv) > 3:
                reg = sys.argv[3]
            elif sys.argv[2].startswith("region:"):
                reg = sys.argv[2][7:]
        return cmd_start(reg, force_slurp=force_slurp)
    if op == "stop":
        return cmd_stop()
    if op == "pause":
        return cmd_pause()
    if op == "audio" and len(sys.argv) >= 4:
        return cmd_audio(sys.argv[2], sys.argv[3], sys.argv[4] if len(sys.argv) > 4 else None)
    if op == "patch" and len(sys.argv) > 2:
        return cmd_patch(sys.argv[2])
    return 2


if __name__ == "__main__":
    sys.exit(main())