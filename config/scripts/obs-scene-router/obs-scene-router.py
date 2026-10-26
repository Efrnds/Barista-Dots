#!/usr/bin/env python3
"""Hyprland focused-window → OBS scene router (Wayland-safe).

Privacy path is hard-cut: blank capture sources first, then Cut 0ms to chatting.
"""

from __future__ import annotations

import argparse
import json
import os
import signal
import socket
import subprocess
import sys
import threading
import time
from dataclasses import dataclass
from pathlib import Path

import obsws_python as obs

ROOT = Path(__file__).resolve().parent
DEFAULT_CONFIG = ROOT / "config.json"
STATE_DIR = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp")) / "obs-scene-router"
PAUSE_FLAG = STATE_DIR / "paused"
FORCE_FLAG = STATE_DIR / "force-scene"
GAME_MODE_FLAG = STATE_DIR / "game-mode"


def expand(path: str) -> Path:
    return Path(os.path.expanduser(path)).resolve()


def load_config(path: Path) -> dict:
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def read_obs_password(cfg: dict) -> str:
    pw_file = expand(cfg["obs"]["password_from"])
    data = json.loads(pw_file.read_text(encoding="utf-8"))
    return data.get("server_password") or ""


def notify(msg: str, urgency: str = "low") -> None:
    try:
        subprocess.run(
            ["notify-send", "-u", urgency, "-t", "1800", "OBS Scene Router", msg],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except FileNotFoundError:
        pass


def hypr_json(cmd: list[str]) -> object:
    out = subprocess.check_output(["hyprctl", "-j", *cmd], text=True)
    return json.loads(out)


def active_window() -> dict | None:
    try:
        win = hypr_json(["activewindow"])
    except (subprocess.CalledProcessError, json.JSONDecodeError):
        return None
    if not isinstance(win, dict):
        return None
    if not win.get("class") and not win.get("address"):
        return None
    return win


def matches(value: str, exact: list[str], contains: list[str] | None = None) -> bool:
    v = value or ""
    vl = v.lower()
    for item in exact:
        if not item:
            continue
        if item.endswith("_") and vl.startswith(item.lower()):
            return True
        if vl == item.lower() or v == item:
            return True
    for item in contains or []:
        if item and item.lower() in vl:
            return True
    return False


def is_privacy(win: dict | None, cfg: dict) -> bool:
    """True for Zap/WhatsApp — by class OR title (incl. Zen PWA tab)."""
    if win is None:
        return False
    cls = win.get("class") or win.get("initialClass") or ""
    title = win.get("title") or win.get("initialTitle") or ""
    # Title match wins even for otherwise-ignored classes (belt-and-suspenders).
    if matches(title, [], cfg.get("privacy_title_contains", [])):
        return True
    if matches(cls, cfg.get("ignore_classes", [])):
        return False
    return matches(cls, cfg.get("privacy_classes", []), cfg.get("privacy_title_contains", []))


def _monitor_displayed_workspace(mon: dict) -> str | None:
    """Workspace currently painted on a monitor (special takes priority when open)."""
    special = mon.get("specialWorkspace") or {}
    special_name = special.get("name") or ""
    if special_name:
        return special_name
    active = mon.get("activeWorkspace") or {}
    return active.get("name")


def privacy_window_visible(cfg: dict) -> dict | None:
    """Any open WhatsApp/Zap window (app or Zen tab).

    Used only to bounce OBS off capture scenes. Workspace filters were too
    clever and missed real leaks (Zap on another ws still showed in PipeWire).
    """
    focused = active_window()
    if focused is not None and is_privacy(focused, cfg):
        return focused

    try:
        clients = hypr_json(["clients"])
    except (subprocess.CalledProcessError, json.JSONDecodeError):
        return None
    if not isinstance(clients, list):
        return None

    for win in clients:
        if not isinstance(win, dict):
            continue
        if not win.get("mapped") or win.get("hidden"):
            continue
        if is_privacy(win, cfg):
            return win
    return None


def is_capture_source_name(name: str, cfg: dict) -> bool:
    exact = cfg.get("capture_source_names", [])
    contains = cfg.get("capture_source_name_contains", [
        "Captura de monitor",
        "Captura de jogo",
        "Display Capture",
        "Game Capture",
        "Screen Capture",
    ])
    return matches(name, exact, contains)


@dataclass
class Decision:
    scene: str | None
    privacy: bool = False


def classify(win: dict | None, cfg: dict) -> Decision:
    scenes = cfg["scenes"]
    game_mode = GAME_MODE_FLAG.exists()

    # Desktop vazio / sem janela: não empurra Just chatting sozinho.
    if win is None:
        if game_mode:
            return Decision(scenes["gameplay"])
        return Decision(None)

    cls = win.get("class") or win.get("initialClass") or ""
    title = win.get("title") or win.get("initialTitle") or ""
    content = str(win.get("contentType") or "").lower()

    if matches(cls, cfg.get("ignore_classes", [])):
        return Decision(None)

    # Único auto → Just chatting: Zap / WhatsApp (app ou aba).
    if is_privacy(win, cfg):
        return Decision(scenes["chatting"], privacy=True)

    is_game = (
        content == "game"
        or matches(cls, cfg.get("game_classes", []), cfg.get("game_title_contains", []))
        or matches(cls, cfg.get("game_launcher_classes", []))
        or matches(title, [], cfg.get("game_title_contains", []))
    )
    if is_game:
        return Decision(scenes["gameplay"])

    is_programming = matches(
        cls, cfg.get("programming_classes", []), cfg.get("programming_title_contains", [])
    ) or matches(title, [], cfg.get("programming_title_contains", []))

    if is_programming:
        # Em modo jogo, browser/IDE não roubam a cena da live.
        if game_mode:
            return Decision(scenes["gameplay"])
        return Decision(scenes["programming"])

    if game_mode:
        return Decision(scenes["gameplay"])

    return Decision(None)


def parse_activewindow_event(line: str) -> dict | None:
    """Parse `activewindow>>class,title` from Hyprland socket2."""
    if line.startswith("activewindow>>"):
        payload = line[len("activewindow>>") :]
        if "," not in payload:
            return {"class": payload, "title": ""}
        cls, title = payload.split(",", 1)
        return {"class": cls, "title": title}
    return None


class Router:
    def __init__(self, cfg: dict):
        self.cfg = cfg
        self.client: obs.ReqClient | None = None
        self.events: obs.EventClient | None = None
        self.current_scene: str | None = None
        self.last_target: str | None = None
        self._saved_transition: tuple[str, int] | None = None
        self._lock = threading.Lock()
        self._stop = threading.Event()
        STATE_DIR.mkdir(parents=True, exist_ok=True)

    def connect(self) -> None:
        host = self.cfg["obs"]["host"]
        port = int(self.cfg["obs"]["port"])
        password = read_obs_password(self.cfg)
        while not self._stop.is_set():
            try:
                self.client = obs.ReqClient(host=host, port=port, password=password, timeout=3)
                self.current_scene = self.client.get_current_program_scene().current_program_scene_name
                self._connect_events(host, port, password)
                print(f"[obs] connected — scene={self.current_scene}", flush=True)
                return
            except Exception:  # noqa: BLE001
                print(f"[obs] waiting for websocket on {host}:{port}", flush=True)
                time.sleep(2)

    def _connect_events(self, host: str, port: int, password: str) -> None:
        """Listen for manual OBS scene changes (e.g. user clicks Programming with Zap up)."""
        try:
            if self.events is not None:
                try:
                    self.events.disconnect()
                except Exception:  # noqa: BLE001
                    pass
                self.events = None

            self.events = obs.EventClient(host=host, port=port, password=password, timeout=3)

            def on_current_program_scene_changed(data):  # noqa: ANN001
                name = getattr(data, "scene_name", None) or getattr(data, "current_program_scene_name", None)
                if not name and isinstance(data, dict):
                    name = data.get("scene_name") or data.get("sceneName")
                if name:
                    self.current_scene = str(name)
                print(f"[obs] scene changed → {self.current_scene}", flush=True)
                # If they jumped to a capture scene while Zap is showing, bounce back.
                self.enforce_privacy_for_obs_scene(reason="obs-scene-change")

            self.events.callback.register(on_current_program_scene_changed)
            print("[obs] watching CurrentProgramSceneChanged", flush=True)
        except Exception as exc:  # noqa: BLE001
            print(f"[obs] event subscribe failed: {type(exc).__name__}", flush=True)
            self.events = None

    def capture_scene_names(self) -> set[str]:
        scenes = self.cfg["scenes"]
        return {scenes["gameplay"], scenes["programming"]}

    def enforce_privacy_for_obs_scene(self, reason: str = "privacy") -> bool:
        """If OBS is on a capture scene and Zap is up, force Just chatting."""
        if not self.ensure_client():
            return False
        if (self.current_scene or "") not in self.capture_scene_names():
            return False
        priv = privacy_window_visible(self.cfg)
        if priv is None:
            return False
        cls = priv.get("class", "?")
        title = priv.get("title", "")
        self.emergency_privacy(f"{reason} {cls} | {title[:60]}")
        return True

    def ensure_client(self) -> bool:
        if self.client is None:
            self.connect()
        try:
            assert self.client is not None
            self.current_scene = self.client.get_current_program_scene().current_program_scene_name
            return True
        except Exception as exc:  # noqa: BLE001
            print(f"[obs] reconnect: {type(exc).__name__}", flush=True)
            self.client = None
            self.connect()
            return self.client is not None

    def paused(self) -> bool:
        return PAUSE_FLAG.exists()

    def forced_scene(self) -> str | None:
        if not FORCE_FLAG.exists():
            return None
        try:
            return FORCE_FLAG.read_text(encoding="utf-8").strip() or None
        except OSError:
            return None

    def on_manual_scene(self) -> bool:
        manual = set(self.cfg["scenes"].get("manual", []))
        return (self.current_scene or "") in manual

    def on_capture_scene(self) -> bool:
        scenes = self.cfg["scenes"]
        return self.current_scene in {scenes["gameplay"], scenes["programming"]}

    def _iter_capture_items(self, scene: str):
        assert self.client is not None
        items = self.client.get_scene_item_list(scene).scene_items
        for it in items:
            name = it.get("sourceName") or ""
            if is_capture_source_name(name, self.cfg):
                yield name, int(it["sceneItemId"])

    def blank_captures(self, scenes: list[str] | None = None) -> None:
        """Hide monitor/game captures immediately (before scene change)."""
        assert self.client is not None
        if scenes is None:
            scenes = [
                self.cfg["scenes"]["gameplay"],
                self.cfg["scenes"]["programming"],
                self.current_scene or "",
            ]
        seen: set[tuple[str, int]] = set()
        for scene in scenes:
            if not scene:
                continue
            try:
                for name, item_id in self._iter_capture_items(scene):
                    key = (scene, item_id)
                    if key in seen:
                        continue
                    seen.add(key)
                    self.client.set_scene_item_enabled(scene, item_id, False)
                    print(f"[privacy] blank {scene!r} / {name!r}", flush=True)
            except Exception as exc:  # noqa: BLE001
                print(f"[privacy] blank failed on {scene!r}: {type(exc).__name__}", flush=True)

    def restore_captures(self, scenes: list[str] | None = None) -> None:
        assert self.client is not None
        if scenes is None:
            scenes = [self.cfg["scenes"]["gameplay"], self.cfg["scenes"]["programming"]]
        for scene in scenes:
            try:
                for name, item_id in self._iter_capture_items(scene):
                    self.client.set_scene_item_enabled(scene, item_id, True)
                    print(f"[privacy] restore {scene!r} / {name!r}", flush=True)
            except Exception as exc:  # noqa: BLE001
                print(f"[privacy] restore failed on {scene!r}: {type(exc).__name__}", flush=True)

    def _find_cut_transition_name(self) -> str | None:
        assert self.client is not None
        try:
            lst = self.client.get_scene_transition_list()
            transitions = getattr(lst, "transitions", None) or []
            for t in transitions:
                kind = (t.get("transitionKind") or t.get("transition_kind") or "").lower()
                name = t.get("transitionName") or t.get("transition_name") or ""
                if "cut" in kind or name.lower() in {"cut", "cortar"}:
                    return name
        except Exception:  # noqa: BLE001
            return None
        return None

    def force_cut_transition(self) -> None:
        assert self.client is not None
        try:
            cur = self.client.get_current_scene_transition()
            name = getattr(cur, "transition_name", None) or getattr(cur, "current_scene_transition_name", None)
            dur = getattr(cur, "transition_duration", None) or getattr(cur, "current_scene_transition_duration", None)
            if name is not None and dur is not None:
                self._saved_transition = (str(name), int(dur))
            cut = self._find_cut_transition_name() or "Cortar"
            self.client.set_current_scene_transition(cut)
            # OBS rejects durations below 50ms; Cut ignores duration anyway.
            try:
                self.client.set_current_scene_transition_duration(50)
            except Exception:  # noqa: BLE001
                pass
        except Exception as exc:  # noqa: BLE001
            print(f"[privacy] cut transition failed: {type(exc).__name__}: {exc}", flush=True)

    def restore_transition(self) -> None:
        if not self._saved_transition or self.client is None:
            return
        name, dur = self._saved_transition
        self._saved_transition = None
        try:
            self.client.set_current_scene_transition(name)
            self.client.set_current_scene_transition_duration(dur)
        except Exception as exc:  # noqa: BLE001
            print(f"[privacy] restore transition failed: {type(exc).__name__}", flush=True)

    def _current_transition_duration_ms(self) -> int:
        assert self.client is not None
        try:
            cur = self.client.get_current_scene_transition()
            dur = getattr(cur, "transition_duration", None) or getattr(
                cur, "current_scene_transition_duration", None
            )
            if dur is None:
                return 1000
            return max(50, int(dur))
        except Exception:  # noqa: BLE001
            return 1000

    def emergency_privacy(self, reason: str) -> None:
        """Hide monitor captures → switch with normal OBS transition → restore captures."""
        restore_after_ms = 0
        with self._lock:
            if not self.ensure_client():
                return
            assert self.client is not None
            target = self.cfg["scenes"]["chatting"]
            try:
                try:
                    self.current_scene = self.client.get_current_program_scene().current_program_scene_name
                except Exception:  # noqa: BLE001
                    pass

                # 1) Kill Zap on the capture sources before any transition frames.
                blanked = bool(self.cfg.get("blank_captures_on_privacy", True))
                if blanked:
                    self.blank_captures()

                # 2) Keep the user's transition (Esmaecer etc.) — safe because capture is blank.
                restore_after_ms = self._current_transition_duration_ms() if blanked else 0
                self.client.set_current_program_scene(target)
                self.current_scene = target
                self.last_target = target
                print(f"[privacy] OBS → {target} ({reason})", flush=True)
            except Exception as exc:  # noqa: BLE001
                print(f"[privacy] emergency failed: {exc}", flush=True)
                self.client = None
                return

        # 3) Re-enable captures after the transition finishes (not mid-fade).
        if restore_after_ms > 0:

            def _restore() -> None:
                with self._lock:
                    if self._stop.is_set() or self.client is None:
                        return
                    try:
                        self.restore_captures()
                    except Exception as exc:  # noqa: BLE001
                        print(f"[privacy] delayed restore failed: {type(exc).__name__}", flush=True)

            threading.Timer(restore_after_ms / 1000.0, _restore).start()

    def switch_to(self, scene: str, reason: str, *, privacy: bool = False) -> None:
        if privacy:
            self.emergency_privacy(reason)
            return

        with self._lock:
            if not scene or scene == self.current_scene:
                return
            if not self.ensure_client():
                return
            assert self.client is not None
            try:
                if scene in {
                    self.cfg["scenes"]["gameplay"],
                    self.cfg["scenes"]["programming"],
                }:
                    self.restore_captures([scene])
                self.client.set_current_program_scene(scene)
                self.current_scene = scene
                self.last_target = scene
                print(f"[switch] → {scene} ({reason})", flush=True)
            except Exception as exc:  # noqa: BLE001
                print(f"[obs] switch failed: {exc}", flush=True)
                self.client = None

    def on_sticky_scene(self) -> bool:
        sticky = set(self.cfg.get("sticky_scenes") or [])
        return (self.current_scene or "") in sticky

    def apply_window(self, win: dict | None, *, from_event: bool = False) -> None:
        # Sync OBS scene first — catches manual clicks in the OBS UI.
        if self.ensure_client():
            pass

        # Zap on screen / focused while OBS is (or becomes) a capture scene.
        if self.enforce_privacy_for_obs_scene(reason="visible"):
            return

        decision = classify(win, self.cfg)

        if decision.privacy:
            cls = (win or {}).get("class", "?")
            title = (win or {}).get("title", "")
            self.emergency_privacy(f"{cls} | {title[:60]}")
            return

        forced = self.forced_scene()
        if forced:
            # Even forced Gameplay/Programming loses to Zap.
            if forced in self.capture_scene_names() and privacy_window_visible(self.cfg):
                self.enforce_privacy_for_obs_scene(reason="force-blocked-by-zap")
                return
            self.switch_to(forced, "force-flag")
            return

        if self.paused() or self.on_manual_scene():
            return

        # Programming (sticky_scenes): só sai no Zap ou na mão.
        if self.on_sticky_scene():
            return

        if decision.scene is None:
            return

        cls = (win or {}).get("class", "<desktop>")
        title = (win or {}).get("title", "")
        reason = f"{cls} | {title[:60]}"
        if from_event:
            reason = "evt " + reason
        self.switch_to(decision.scene, reason, privacy=False)

    def tick(self) -> None:
        if not self.ensure_client():
            return
        # Always re-check after syncing the real OBS program scene.
        if self.enforce_privacy_for_obs_scene(reason="tick"):
            return
        self.apply_window(active_window())

    def follow_hypr_events(self) -> None:
        runtime = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp"))
        his = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
        if not his:
            print("[hypr] HYPRLAND_INSTANCE_SIGNATURE missing; polling only", flush=True)
            return

        sock_path = runtime / "hypr" / his / ".socket2.sock"
        debounce = max(0, int(self.cfg.get("debounce_ms", 100))) / 1000.0

        while not self._stop.is_set():
            try:
                with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
                    sock.connect(str(sock_path))
                    sock.settimeout(0.2)
                    print(f"[hypr] listening on {sock_path}", flush=True)
                    buf = ""
                    while not self._stop.is_set():
                        try:
                            chunk = sock.recv(4096)
                        except socket.timeout:
                            continue
                        if not chunk:
                            break
                        buf += chunk.decode("utf-8", errors="ignore")
                        while "\n" in buf:
                            line, buf = buf.split("\n", 1)
                            # Any focus/title/open change can reveal Zap on the monitor.
                            if (
                                line.startswith("activewindow>>")
                                or line.startswith("activewindowv2>>")
                                or line.startswith("windowtitle>>")
                                or line.startswith("windowtitlev2>>")
                                or line.startswith("openwindow>>")
                                or line.startswith("closewindow>>")
                            ):
                                if line.startswith("activewindow>>"):
                                    win = parse_activewindow_event(line)
                                    if win and is_privacy(win, self.cfg):
                                        self.apply_window(win, from_event=True)
                                        continue
                                # Always scan all clients for visible Zap (unfocused leak).
                                if privacy_window_visible(self.cfg) is not None:
                                    self.tick()
                                    continue
                                if line.startswith("activewindow>>") or line.startswith("activewindowv2>>"):
                                    if debounce:
                                        time.sleep(debounce)
                                    self.tick()
            except Exception as exc:  # noqa: BLE001
                print(f"[hypr] socket error: {exc}; retrying", flush=True)
                time.sleep(0.5)

    def run(self) -> None:
        self.connect()
        # Recover captures left disabled by a previous privacy blank/crash.
        try:
            if self.client is not None:
                self.restore_captures()
        except Exception as exc:  # noqa: BLE001
            print(f"[privacy] startup restore failed: {type(exc).__name__}", flush=True)
        self.tick()
        t = threading.Thread(target=self.follow_hypr_events, name="hypr-events", daemon=True)
        t.start()
        # Keep polling fast so a manual OBS scene click with Zap up bounces back quickly,
        # even before / if the websocket event is missed.
        while not self._stop.is_set():
            self.tick()
            self._stop.wait(0.05)  # 20 Hz

    def stop(self, *_args) -> None:
        self._stop.set()


def cmd_status(cfg: dict) -> int:
    win = active_window()
    decision = classify(win, cfg)
    priv = privacy_window_visible(cfg)
    print(f"paused={PAUSE_FLAG.exists()}")
    print(f"game_mode={GAME_MODE_FLAG.exists()}")
    print(f"force={FORCE_FLAG.read_text(encoding='utf-8').strip() if FORCE_FLAG.exists() else ''}")
    if win:
        print(f"class={win.get('class')}")
        print(f"title={win.get('title')}")
        print(f"contentType={win.get('contentType')}")
    else:
        print("class=<none>")
        print("title=<none>")
        print("contentType=<none>")
    print(f"privacy_focused={decision.privacy}")
    print(f"privacy_visible={bool(priv)}")
    if priv:
        print(f"privacy_window={priv.get('class')} | {priv.get('title')}")
    print(f"would_switch_to={cfg['scenes']['chatting'] if priv else decision.scene}")
    return 0


def cmd_toggle_pause() -> int:
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    if PAUSE_FLAG.exists():
        PAUSE_FLAG.unlink()
        notify("Auto scene: ON")
        print("auto=on")
    else:
        PAUSE_FLAG.write_text("1\n", encoding="utf-8")
        notify("Auto scene: OFF")
        print("auto=off")
    return 0


def cmd_force(scene: str | None) -> int:
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    if not scene:
        if FORCE_FLAG.exists():
            FORCE_FLAG.unlink()
        notify("Force scene: cleared")
        print("force=cleared")
        return 0
    FORCE_FLAG.write_text(scene + "\n", encoding="utf-8")
    notify(f"Force scene: {scene}")
    print(f"force={scene}")
    return 0


def cmd_go_live(cfg: dict) -> int:
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    if PAUSE_FLAG.exists():
        PAUSE_FLAG.unlink()
    if FORCE_FLAG.exists():
        FORCE_FLAG.unlink()
    scene = cfg["scenes"]["chatting"]
    try:
        password = read_obs_password(cfg)
        client = obs.ReqClient(
            host=cfg["obs"]["host"],
            port=int(cfg["obs"]["port"]),
            password=password,
            timeout=3,
        )
        client.set_current_program_scene(scene)
        notify(f"Auto ON → {scene}")
        print(f"go-live={scene}")
        return 0
    except Exception as exc:  # noqa: BLE001
        FORCE_FLAG.write_text(scene + "\n", encoding="utf-8")
        notify(f"Auto flags set (OBS offline?): {exc}", urgency="normal")
        print(f"go-live-deferred={scene} err={exc}")
        return 1


def main() -> int:
    parser = argparse.ArgumentParser(description="Hyprland → OBS scene router")
    parser.add_argument("--config", type=Path, default=DEFAULT_CONFIG)
    sub = parser.add_subparsers(dest="cmd")

    sub.add_parser("run", help="run daemon (default)")
    sub.add_parser("status", help="print current window classification")
    sub.add_parser("toggle-pause", help="pause/resume automatic switching")
    p_force = sub.add_parser("force", help="force a scene until cleared")
    p_force.add_argument("scene", nargs="?", default=None)
    sub.add_parser("clear-force", help="clear forced scene")
    sub.add_parser("go-live", help="clear locks and switch to Just chatting")

    args = parser.parse_args()
    cfg = load_config(args.config)
    cmd = args.cmd or "run"

    if cmd == "status":
        return cmd_status(cfg)
    if cmd == "toggle-pause":
        return cmd_toggle_pause()
    if cmd == "force":
        return cmd_force(args.scene)
    if cmd == "clear-force":
        return cmd_force(None)
    if cmd == "go-live":
        return cmd_go_live(cfg)

    router = Router(cfg)
    signal.signal(signal.SIGINT, router.stop)
    signal.signal(signal.SIGTERM, router.stop)
    router.run()
    return 0


if __name__ == "__main__":
    sys.exit(main())
