"""Keeps the progress table in .kiro/specs/gearbound-production/tasks.md honest.

Counts the ticked sub-tasks under each phase task and rewrites the table between
the progress markers.

    python -I tools/build/phase_progress.py          # rewrite the table
    python -I tools/build/phase_progress.py --check  # fail if it is stale or inconsistent

The check also fails when a phase box is ticked while one of its sub-tasks is not.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TASKS = ROOT / ".kiro" / "specs" / "gearbound-production" / "tasks.md"
START, END = "<!-- progress:start -->", "<!-- progress:end -->"

PHASE = re.compile(r"^- \[( |x)\] (\d+)\. Phase (\d\d) — (.+)$")
SUB = re.compile(r"^  - \[( |x)\] (\d+)\.(\d+) ")


def parse(text: str) -> tuple[list[dict], list[str]]:
    phases: list[dict] = []
    errors: list[str] = []
    for line in text.splitlines():
        m = PHASE.match(line)
        if m:
            phases.append({"ticked": m.group(1) == "x", "number": int(m.group(2)), "code": m.group(3),
                           "name": m.group(4), "done": 0, "total": 0})
            if int(m.group(2)) != int(m.group(3)):
                errors.append(f"task {m.group(2)} is labeled Phase {m.group(3)}")
            continue
        m = SUB.match(line)
        if m and phases:
            phase = phases[-1]
            if int(m.group(2)) != phase["number"]:
                errors.append(f"sub-task {m.group(2)}.{m.group(3)} sits under phase {phase['number']}")
            phase["total"] += 1
            phase["done"] += m.group(1) == "x"
    for phase in phases:
        if phase["total"] == 0:
            errors.append(f"Phase {phase['code']} has no sub-tasks")
        complete = phase["done"] == phase["total"]
        if phase["ticked"] != complete:
            state = "ticked" if phase["ticked"] else "unticked"
            errors.append(f"Phase {phase['code']} is {state} but {phase['done']}/{phase['total']} sub-tasks are done")
    if [p["number"] for p in phases] != list(range(len(phases))):
        errors.append("phases must be numbered 0, 1, 2, … in order")
    return phases, errors


def pct(done: int, total: int) -> str:
    return f"{done * 100 // total}%" if total else "0%"


def table(phases: list[dict]) -> str:
    rows = ["| Phase | Name | Done | Progress |", "|---|---|---|---|"]
    for p in phases:
        rows.append(f"| {p['code']} | {p['name']} | {p['done']}/{p['total']} | {pct(p['done'], p['total'])} |")
    done = sum(p["done"] for p in phases)
    total = sum(p["total"] for p in phases)
    rows.append(f"| **All** | | **{done}/{total}** | **{pct(done, total)}** |")
    return "\n".join(rows)


def main(argv: list[str]) -> int:
    text = TASKS.read_text(encoding="utf-8")
    phases, errors = parse(text)
    if START not in text or END not in text:
        errors.append("progress markers are missing")
    if errors:
        for error in errors:
            print("tasks.md:", error)
        return 1
    head, rest = text.split(START, 1)
    _, tail = rest.split(END, 1)
    updated = f"{head}{START}\n{table(phases)}\n{END}{tail}"
    if "--check" in argv:
        if updated != text:
            print("tasks.md progress table is stale; run python -I tools/build/phase_progress.py")
            return 1
        done = sum(p["done"] for p in phases)
        total = sum(p["total"] for p in phases)
        print(f"phase progress up to date ({done}/{total} sub-tasks)")
        return 0
    TASKS.write_text(updated, encoding="utf-8", newline="\n")
    print("updated", TASKS.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
