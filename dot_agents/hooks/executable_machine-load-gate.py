#!/usr/bin/env python3
"""PreToolUse hook: let only a few heavy jobs run on this machine at once.

Many agents share one machine. Each one starts test runs, builds and type
checks without knowing about the others, and together they use every core
and push the machine into swap.

Reads the hook JSON on stdin (Claude Code, Codex or Cursor). A shell command that
starts a heavy job waits here until fewer than SLOTS heavy jobs are running.
If it still has no turn after MAX_WAIT seconds, the hook refuses the command
and tells the agent what is running. Any other command passes at once.

The hook never blocks on its own errors: if it fails, the command runs.
"""

import json
import os
import re
import subprocess
import sys
import time

CORES = os.cpu_count() or 4
# ~/.zshenv caps each job at about a third of the cores, so this many jobs fit.
SLOTS = int(os.environ.get("MACHINE_LOAD_GATE_SLOTS") or max(2, CORES // 4))
MAX_WAIT = int(os.environ.get("MACHINE_LOAD_GATE_WAIT") or 240)
POLL = 4
# A job older than this is a watcher or is stuck. It must not hold a turn forever.
MAX_JOB_AGE = 30 * 60
# A job that just got a turn does not show in `ps` yet. Count it for this long.
RESERVATION_AGE = 12
STATE = os.path.join(
    os.environ.get("XDG_CACHE_HOME") or os.path.expanduser("~/.cache"),
    "machine-load-gate",
)

# Where a command can start: the start of the line, after a shell operator,
# or after a wrapper such as `npx`. Variable assignments may come first.
START = (
    r"(?:^|[;&|({]|\b(?:then|do|time|exec|env|nice|npx|bunx|pnpx|xargs|corepack|caffeinate(?:\s+-\w+)*|timeout\s+\S+)(?=\s)|\b(?:ba|z)?sh\s+-l?c\s+[\'\"]?)\s*"
    r"(?:[A-Za-z_][A-Za-z0-9_]*=\S*\s+)*"
)
RUNNER = r"(?:pnpm|npm|yarn|bun|vp)(?:\s+(?:run|exec|-s|--silent|-r|-w|(?:--filter|--dir|-F|-C)[\s=]\S+))*\s+"
HEAVY_COMMAND = re.compile(
    START
    + r"(?:"
    + r"(?:" + RUNNER + r")?(?:\S*/)?(?:vitest|jest|tsc|tsgo|turbo|nx|xcodebuild)(?=[\s\'\")]|$)"
    + r"|(?:" + RUNNER + r")?playwright\s+test\b"
    + r"|(?:" + RUNNER + r")?(?:next|vite)\s+build\b"
    + r"|go\s+(?:build|test|vet|install)\b"
    + r"|cargo\s+(?:\+\S+\s+)?(?:build|test|check|clippy|run|nextest|tauri|install)\b"
    + r"|swift\s+(?:build|test)\b"
    + r"|" + RUNNER + r"(?:tests?|check|typecheck|type-check|build|verify|validate|ci|e2e)(?::[\w:-]+)?(?=[\s\'\")]|$)"
    + r")",
    re.MULTILINE,
)

# The one process that stands for each running job, as `ps` shows it.
JOBS = (
    ("tests", re.compile(r"/vitest/vitest\.mjs|^node \(vitest\)|(?:^|/)go\s+test\b|(?:^|/)bun(?:\.exe)?\s+test\b|/jest/bin/jest|/playwright(?:-core)?/cli\.js\s+test\b|/@playwright/test/cli\.js\s+test\b")),
    ("type check", re.compile(r"(?:^|/)(?:tsc|tsgo)(?:\s|$)|/typescript/(?:bin|lib)/tsc\b")),
    ("build", re.compile(r"/next/dist/bin/next\s+build|/vite/bin/vite\.js\s+build|(?:^|/)go\s+(?:build|vet|install)\b|(?:^|/)(?:xcodebuild|swift-build)(?:\s|$)")),
)
# The shell that an agent command runs in repeats the command text. Skip it.
SHELL = re.compile(r"^\S*(?:zsh|bash|sh)\s+-")
# `cargo run` and `cargo tauri dev` stay alive while the app runs, so they count
# only while they compile: one job for each group of rustc processes.
CARGO = re.compile(r"(?:^|/)cargo(?:-\w+)?\s+(?:\+\S+\s+)?(?:build|test|check|clippy|nextest|install)\b")
RUSTC = re.compile(r"(?:^|/)rustc(?:\s|$)")
WATCHER = re.compile(r"\s(?:--watch|-w|watch)(?:\s|$)")


def command_of(payload):
    command = (payload.get("tool_input") or {}).get("command") or payload.get("command")
    if isinstance(command, list):
        # Codex sends ["bash", "-lc", "<script>"]. Check each part by itself.
        command = "\n".join(str(part) for part in command)
    return command if isinstance(command, str) else ""


def seconds(etime):
    """`ps` prints elapsed time as [[dd-]hh:]mm:ss."""
    days, _, clock = etime.rpartition("-")
    parts = [int(part) for part in clock.split(":")]
    while len(parts) < 3:
        parts.insert(0, 0)
    return int(days or 0) * 86400 + parts[0] * 3600 + parts[1] * 60 + parts[2]


def running_jobs():
    """Return one (kind, age in seconds, command) for each heavy job."""
    output = subprocess.run(
        ["ps", "-Ao", "pid=,ppid=,etime=,command="],
        capture_output=True, text=True, timeout=20,
    ).stdout
    jobs = []
    cargo = set()
    rust_builds = {}
    for line in output.splitlines():
        fields = line.split(None, 3)
        if len(fields) < 4:
            continue
        pid, parent, etime, command = fields
        age = seconds(etime)
        if RUSTC.search(command):
            # One cargo build runs many rustc processes. Count the build once.
            rust_builds[parent] = max(age, rust_builds.get(parent, 0))
            continue
        if age > MAX_JOB_AGE or WATCHER.search(command) or SHELL.search(command):
            continue
        if CARGO.search(command):
            cargo.add(pid)
            jobs.append(("rust build or test", age, command))
            continue
        for kind, pattern in JOBS:
            if pattern.search(command):
                jobs.append((kind, age, command))
                break
    jobs += [
        ("rust build", age, "cargo")
        for parent, age in rust_builds.items()
        if parent not in cargo
    ]
    return jobs


def reservations(now):
    count = 0
    for name in os.listdir(STATE):
        path = os.path.join(STATE, name)
        if not name.endswith(".turn"):
            continue
        try:
            if now - os.path.getmtime(path) < RESERVATION_AGE:
                count += 1
            else:
                os.unlink(path)
        except OSError:
            pass
    return count


def take_turn():
    """Take a turn if one is free. Return the jobs that are in the way."""
    import fcntl

    with open(os.path.join(STATE, "lock"), "w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        jobs = running_jobs()
        if len(jobs) + reservations(time.time()) < SLOTS:
            open(os.path.join(STATE, f"{os.getpid()}.turn"), "w").close()
            return None
        return jobs


def describe(jobs):
    home = os.path.expanduser("~")
    lines = []
    for kind, age, command in sorted(jobs, key=lambda job: -job[1]):
        where = re.search(r"/(?:worktrees/[^/\s]+|src|scratch)/[^/\s]+", command)
        place = where.group(0).lstrip("/") if where else command.replace(home, "~")[:70]
        lines.append(f"  - {kind}, running {age // 60} min {age % 60} s: {place}")
    return "\n".join(lines)


def refuse(jobs, cursor):
    load = os.getloadavg()[0]
    reason = (
        f"This command did not run. It starts a heavy job, and this machine "
        f"lets {SLOTS} heavy jobs (tests, builds, type checks) run at once, "
        f"because other agents share it. It waited {MAX_WAIT} seconds for a "
        f"turn. The load is {load:.0f} on {CORES} cores. Running now:\n"
        f"{describe(jobs)}\n"
        "Run the same command again to wait for the next turn. To need less "
        "time when your turn comes, run only the test files for what you "
        "changed. Do not rewrite the command to get past this check. If a "
        "job in the list is yours and is stuck, stop it."
    )
    if cursor:
        print(json.dumps({"permission": "deny", "agent_message": reason, "user_message": reason.split(". ")[0] + "."}))
        return
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }))


def main():
    payload = json.load(sys.stdin)
    command = command_of(payload)
    if not HEAVY_COMMAND.search(command):
        return
    os.makedirs(STATE, exist_ok=True)
    deadline = time.time() + MAX_WAIT
    while True:
        jobs = take_turn()
        if jobs is None:
            return
        if time.time() + POLL > deadline:
            refuse(jobs, payload.get("hook_event_name") == "beforeShellExecution")
            return
        time.sleep(POLL)


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
