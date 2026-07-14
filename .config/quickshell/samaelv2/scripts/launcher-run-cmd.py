#!/usr/bin/env python3
"""Run a short shell command for launcher /t; JSON stdout for UI."""
import json
import subprocess
import sys

TIMEOUT = 12
MAX_OUT = 12000
MAX_ERR = 6000


def main() -> None:
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    cmd = cmd.strip()
    if not cmd:
        print(json.dumps({"exitCode": -1, "stdout": "", "stderr": "empty command", "command": ""}))
        return
    try:
        r = subprocess.run(
            ["zsh", "-lc", cmd],
            capture_output=True,
            text=True,
            timeout=TIMEOUT,
            env=None,
        )
        out = (r.stdout or "")[-MAX_OUT:]
        err = (r.stderr or "")[-MAX_ERR:]
        print(
            json.dumps(
                {
                    "exitCode": int(r.returncode),
                    "stdout": out,
                    "stderr": err,
                    "command": cmd,
                },
                ensure_ascii=False,
            )
        )
    except subprocess.TimeoutExpired:
        print(
            json.dumps(
                {
                    "exitCode": 124,
                    "stdout": "",
                    "stderr": f"timeout ({TIMEOUT}s)",
                    "command": cmd,
                }
            )
        )
    except Exception as e:
        print(
            json.dumps(
                {
                    "exitCode": -1,
                    "stdout": "",
                    "stderr": str(e)[:500],
                    "command": cmd,
                }
            )
        )


if __name__ == "__main__":
    main()