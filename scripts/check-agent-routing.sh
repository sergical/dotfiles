#!/bin/sh
set -eu

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repository_root"

python3 - <<'PY'
from __future__ import annotations

import pathlib
import re

root = pathlib.Path.cwd()

required = [
    ".chezmoitemplates/shared-agent-guidance.md",
    "dot_agents/AGENTS.md.tmpl",
    "dot_agents/skills/simplify-code/SKILL.md",
    "dot_agents/skills/simplify-code/agents/openai.yaml",
    "dot_agents/skills/dev-servers/SKILL.md",
    "dot_agents/skills/diff-review/SKILL.md",
    "dot_agents/skills/pr-body/SKILL.md",
    "dot_agents/skills/video-context/SKILL.md",
    "private_dot_cursor/rules/shared-agent-guidance.mdc.tmpl",
    "dot_codex/symlink_AGENTS.md",
    "dot_codex/hooks.json.tmpl",
    "dot_codex/modify_private_config.toml",
    "private_dot_claude/CLAUDE.md",
    "private_dot_claude/private_settings.json.tmpl",
    "private_dot_config/private_opencode/agents/plan.md",
    "private_dot_config/private_opencode/symlink_AGENTS.md",
    "private_dot_pi/agent/settings.json.tmpl",
    "private_dot_pi/agent/symlink_AGENTS.md",
]
missing = [path for path in required if not (root / path).is_file()]
if missing:
    raise SystemExit("Missing routing source:\n  " + "\n  ".join(missing))

skill = (root / "dot_agents/skills/simplify-code/SKILL.md").read_text()
if not re.search(r"(?m)^name: simplify-code$", skill):
    raise SystemExit("simplify-code skill name is missing or changed")
for phrase in ("checks are not green", "same relevant checks", "no worthwhile simplification"):
    if phrase not in skill:
        raise SystemExit(f"simplify-code lost required contract: {phrase}")

shared = 'template "shared-agent-guidance.md"'
if shared not in (root / "dot_agents/AGENTS.md.tmpl").read_text():
    raise SystemExit("~/.agents/AGENTS.md must render the shared guidance template")

cursor = (root / "private_dot_cursor/rules/shared-agent-guidance.mdc.tmpl").read_text()
if shared not in cursor or "alwaysApply: true" not in cursor:
    raise SystemExit("Cursor must always load the shared guidance template")

# Every session of every harness loads this file, so each line costs context.
max_shared_lines = 120
shared_lines = len((root / ".chezmoitemplates/shared-agent-guidance.md").read_text().splitlines())
if shared_lines > max_shared_lines:
    raise SystemExit(
        f".chezmoitemplates/shared-agent-guidance.md has {shared_lines} lines; the limit is {max_shared_lines}. "
        "Move procedures into a skill that loads on demand, or delete rules that a check already enforces. "
        "Do not raise the limit or compress lines to pass."
    )

for link in (
    "dot_codex/symlink_AGENTS.md",
    "private_dot_config/private_opencode/symlink_AGENTS.md",
    "private_dot_pi/agent/symlink_AGENTS.md",
):
    target = (root / link).read_text().strip()
    if not target.endswith(".agents/AGENTS.md"):
        raise SystemExit(f"{link} must point to ~/.agents/AGENTS.md, found {target}")

tracked_agent_files = [
    *root.glob(".chezmoitemplates/*"),
    *root.glob("dot_agents/**/*.md"),
    *root.glob("dot_agents/**/*.tmpl"),
    *root.glob("dot_codex/**/*"),
    *root.glob("private_dot_claude/**/*.md"),
    *root.glob("private_dot_config/private_opencode/agents/*.md"),
    *root.glob("private_dot_pi/agent/**/*"),
]
for path in tracked_agent_files:
    if path.is_file() and re.search(r"/Users/[^/]+/", path.read_text()):
        raise SystemExit(f"Machine-specific home path found in {path}")

print("Agent routing source is complete and internally consistent.")
PY
