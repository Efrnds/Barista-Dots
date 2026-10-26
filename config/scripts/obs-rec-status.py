#!/usr/bin/env python3
"""OBS record/stream status for DMS bar. Uses obs-scene-router venv + websocket."""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

ROOT = Path.home() / ".config/scripts/obs-scene-router"
VENV_SITE = next(ROOT.glob(".venv/lib/python*/site-packages"), None)
if VENV_SITE:
    sys.path.insert(0, str(VENV_SITE))

DEFAULT = {
    "connected": False,
    "recording": False,
    "streaming": False,
    "paused": False,
    "bytes": 0,
    "duration_sec": 0,
}


def load_ws() -> tuple[str, int, str]:
    cfg_path = Path.home() / ".config/obs-studio/plugin_config/obs-websocket/config.json"
    host, port, pw = "localhost", 4455, ""
    if cfg_path.exists():
        data = json.loads(cfg_path.read_text(encoding="utf-8"))
        port = int(data.get("ServerPort") or data.get("server_port") or 4455)
        pw = data.get("ServerPassword") or data.get("server_password") or ""
    router = ROOT / "config.json"
    if router.exists():
        r = json.loads(router.read_text(encoding="utf-8"))
        obs = r.get("obs") or {}
        host = obs.get("host") or host
        port = int(obs.get("port") or port)
        pf = obs.get("password_from")
        if pf:
            p = Path(os.path.expanduser(pf))
            if p.exists():
                data = json.loads(p.read_text(encoding="utf-8"))
                pw = data.get("ServerPassword") or data.get("server_password") or pw
    return host, port, pw


def client():
    import obsws_python as obs

    host, port, pw = load_ws()
    return obs.ReqClient(host=host, port=port, password=pw, timeout=1.5)


def status() -> dict:
    import contextlib
    import io

    out = dict(DEFAULT)
    # websocket lib prints ConnectionRefusedError traceback to stderr on connect fail
    with contextlib.redirect_stderr(io.StringIO()):
        try:
            c = client()
            rec = c.get_record_status()
            out["connected"] = True
            out["recording"] = bool(getattr(rec, "output_active", False))
            out["paused"] = bool(getattr(rec, "output_paused", False))
            out["bytes"] = int(getattr(rec, "output_bytes", 0) or 0)
            dur = getattr(rec, "output_duration", 0) or 0
            if isinstance(dur, (int, float)):
                out["duration_sec"] = int(dur / 1000) if dur > 10000 else int(dur)
            try:
                st = c.get_stream_status()
                out["streaming"] = bool(getattr(st, "output_active", False))
            except Exception:
                pass
        except Exception:
            pass
    return out


def do_action(action: str) -> dict:
    out = status()
    if not out["connected"]:
        out["error"] = "obs offline"
        return out
    c = client()
    if action == "toggle-pause":
        if out["recording"]:
            c.toggle_record_pause()
        else:
            out["error"] = "not recording"
    elif action == "stop":
        if out["recording"] or out["paused"]:
            c.stop_record()
        else:
            out["error"] = "not recording"
    elif action == "toggle-record":
        c.toggle_record()
    else:
        out["error"] = f"unknown action {action}"
        return out
    return status()


def main() -> int:
    cmd = sys.argv[1] if len(sys.argv) > 1 else "status"
    if cmd == "status":
        print(json.dumps(status()))
    elif cmd in ("toggle-pause", "stop", "toggle-record"):
        print(json.dumps(do_action(cmd)))
    else:
        print(json.dumps({"error": f"usage: {sys.argv[0]} status|toggle-pause|stop|toggle-record"}))
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
