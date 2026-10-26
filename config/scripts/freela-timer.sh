#!/usr/bin/env bash
# Freela / billing timer — state in ~/.local/state/barista/freela.json
# Commands: status | start <p> | stop | toggle <p> | list | invoice [week|today]
set -euo pipefail

export STATE="${XDG_STATE_HOME:-$HOME/.local/state}/barista/freela.json"
export PROJECTS_ROOT="${FREELA_PROJECTS_ROOT:-$HOME/Documents/Projetos}"
export INVOICE_DIR="${FREELA_INVOICE_DIR:-$HOME/Documents/Freela}"
mkdir -p "$(dirname "$STATE")"

exec python3 - "$@" <<'PY'
import csv, json, os, sys, time
from collections import defaultdict
from datetime import datetime, timedelta
from pathlib import Path

state_path = Path(os.environ["STATE"])
projects_root = Path(os.environ["PROJECTS_ROOT"])
invoice_dir = Path(os.environ["INVOICE_DIR"])
argv = sys.argv[1:]
cmd = argv[0] if argv else "status"

def load():
    if not state_path.exists():
        return {"active": None, "sessions": [], "projects": {}}
    try:
        return json.loads(state_path.read_text())
    except Exception:
        return {"active": None, "sessions": [], "projects": {}}

def save(data):
    state_path.parent.mkdir(parents=True, exist_ok=True)
    state_path.write_text(json.dumps(data, indent=2) + "\n")

def now():
    return int(time.time())

def today_key(ts=None):
    return time.strftime("%Y-%m-%d", time.localtime(ts or now()))

def fmt(sec):
    sec = max(0, int(sec))
    h, r = divmod(sec, 3600)
    m, s = divmod(r, 60)
    if h:
        return f"{h}h{m:02d}m"
    return f"{m}m{s:02d}s"

def fmt_hours(sec):
    return round(max(0, int(sec)) / 3600.0, 2)

def elapsed(data):
    a = data.get("active")
    if not a:
        return 0
    return max(0, now() - int(a.get("started_at", now())))

def today_total(data, project=None):
    total = 0
    day = today_key()
    for s in data.get("sessions", []):
        if today_key(s.get("started_at", 0)) != day:
            continue
        if project and s.get("project") != project:
            continue
        total += int(s.get("duration", 0) or 0)
    a = data.get("active")
    if a and today_key(a.get("started_at", 0)) == day:
        if not project or a.get("project") == project:
            total += elapsed(data)
    return total

def list_projects(data):
    names = set()
    if projects_root.is_dir():
        for p in projects_root.iterdir():
            if p.is_dir() and not p.name.startswith("."):
                names.add(p.name)
    names.update((data.get("projects") or {}).keys())
    a = data.get("active")
    if a and a.get("project"):
        names.add(a["project"])
    return sorted(names, key=str.lower)

def stop(data):
    a = data.get("active")
    if not a:
        return data, False
    dur = max(0, now() - int(a["started_at"]))
    data.setdefault("sessions", []).append({
        "project": a["project"],
        "started_at": a["started_at"],
        "ended_at": now(),
        "duration": dur,
    })
    data["sessions"] = data["sessions"][-500:]
    proj = a["project"]
    data.setdefault("projects", {}).setdefault(proj, {"total_sec": 0})
    data["projects"][proj]["total_sec"] = int(data["projects"][proj].get("total_sec", 0)) + dur
    data["active"] = None
    return data, True

def start(data, project):
    data, _ = stop(data)
    data["active"] = {"project": project, "started_at": now()}
    data.setdefault("projects", {}).setdefault(project, {"total_sec": 0})
    return data

def status_obj(data):
    a = data.get("active")
    projects = []
    for name in list_projects(data)[:40]:
        projects.append({
            "name": name,
            "today_sec": today_total(data, name),
            "today": fmt(today_total(data, name)),
            "active": bool(a and a.get("project") == name),
        })
    return {
        "running": bool(a),
        "project": (a or {}).get("project"),
        "elapsed_sec": elapsed(data) if a else 0,
        "elapsed": fmt(elapsed(data)) if a else "0m00s",
        "today_sec": today_total(data),
        "today": fmt(today_total(data)),
        "projects": projects,
    }

def period_bounds(kind: str):
    # local midnight-based
    now_dt = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
    if kind == "today":
        start_dt = now_dt
        end_dt = now_dt + timedelta(days=1)
        label = today_key()
    else:  # week = Monday..Sunday containing today
        start_dt = now_dt - timedelta(days=now_dt.weekday())
        end_dt = start_dt + timedelta(days=7)
        label = f"{start_dt.strftime('%Y-%m-%d')}_a_{ (end_dt - timedelta(days=1)).strftime('%Y-%m-%d') }"
    return int(start_dt.timestamp()), int(end_dt.timestamp()), label

def sessions_in_range(data, start_ts, end_ts):
    rows = []
    for s in data.get("sessions", []):
        st = int(s.get("started_at", 0) or 0)
        if start_ts <= st < end_ts:
            rows.append(dict(s))
    a = data.get("active")
    if a:
        st = int(a.get("started_at", 0) or 0)
        if start_ts <= st < end_ts:
            rows.append({
                "project": a["project"],
                "started_at": st,
                "ended_at": now(),
                "duration": elapsed(data),
                "active": True,
            })
    return rows

def make_invoice(data, kind="week"):
    start_ts, end_ts, label = period_bounds(kind)
    rows = sessions_in_range(data, start_ts, end_ts)
    by_proj = defaultdict(int)
    for s in rows:
        by_proj[s.get("project") or "?"] += int(s.get("duration", 0) or 0)
    total = sum(by_proj.values())
    invoice_dir.mkdir(parents=True, exist_ok=True)
    base = invoice_dir / f"invoice-{kind}-{label}"
    md_path = base.with_suffix(".md")
    csv_path = base.with_suffix(".csv")

    lines = [
        f"# Freela invoice · {kind}",
        f"",
        f"Período: `{label}`",
        f"Gerado: {datetime.now().strftime('%Y-%m-%d %H:%M')}",
        f"",
        f"## Resumo por projeto",
        f"",
        f"| Projeto | Tempo | Horas |",
        f"|---|---:|---:|",
    ]
    for proj, sec in sorted(by_proj.items(), key=lambda x: -x[1]):
        lines.append(f"| {proj} | {fmt(sec)} | {fmt_hours(sec):.2f} |")
    lines += [
        f"| **Total** | **{fmt(total)}** | **{fmt_hours(total):.2f}** |",
        f"",
        f"## Sessões",
        f"",
        f"| Projeto | Início | Fim | Duração |",
        f"|---|---|---|---:|",
    ]
    for s in sorted(rows, key=lambda x: x.get("started_at", 0)):
        st = time.strftime("%Y-%m-%d %H:%M", time.localtime(int(s["started_at"])))
        en = time.strftime("%Y-%m-%d %H:%M", time.localtime(int(s.get("ended_at") or now())))
        flag = " *(ativa)*" if s.get("active") else ""
        lines.append(f"| {s.get('project','?')}{flag} | {st} | {en} | {fmt(int(s.get('duration',0) or 0))} |")
    if not rows:
        lines.append("| — | — | — | 0m00s |")
    md_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

    with csv_path.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["project", "started_at", "ended_at", "duration_sec", "duration", "hours"])
        for s in sorted(rows, key=lambda x: x.get("started_at", 0)):
            dur = int(s.get("duration", 0) or 0)
            w.writerow([
                s.get("project", "?"),
                time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(int(s["started_at"]))),
                time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(int(s.get("ended_at") or now()))),
                dur,
                fmt(dur),
                f"{fmt_hours(dur):.2f}",
            ])

    return {
        "ok": True,
        "period": kind,
        "label": label,
        "total_sec": total,
        "total": fmt(total),
        "hours": fmt_hours(total),
        "projects": {k: {"sec": v, "time": fmt(v), "hours": fmt_hours(v)} for k, v in by_proj.items()},
        "path_md": str(md_path),
        "path_csv": str(csv_path),
        "sessions": len(rows),
    }

data = load()

if cmd == "status":
    print(json.dumps(status_obj(data)))
elif cmd == "list":
    print(json.dumps({"projects": list_projects(data)}))
elif cmd == "stop":
    data, ok = stop(data)
    save(data)
    out = status_obj(data)
    out["ok"] = ok
    print(json.dumps(out))
elif cmd in ("start", "toggle"):
    if len(argv) < 2:
        print(json.dumps({"error": "project required"}))
        sys.exit(1)
    project = argv[1]
    a = data.get("active")
    if cmd == "toggle" and a and a.get("project") == project:
        data, _ = stop(data)
    else:
        data = start(data, project)
    save(data)
    print(json.dumps(status_obj(data)))
elif cmd == "invoice":
    kind = argv[1] if len(argv) > 1 else "week"
    if kind not in ("week", "today"):
        print(json.dumps({"error": "invoice period must be week|today"}))
        sys.exit(1)
    print(json.dumps(make_invoice(data, kind)))
else:
    print(json.dumps({"error": f"unknown cmd {cmd}"}))
    sys.exit(1)
PY
