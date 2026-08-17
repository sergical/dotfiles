#!/bin/sh
set -eu

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repository_root"

python3 - <<'PY'
from __future__ import annotations

import json
import pathlib
import re
import tomllib

root = pathlib.Path.cwd()

required = [
    ".chezmoitemplates/shared-agent-guidance.md",
    "dot_agents/AGENTS.md.tmpl",
    "dot_agents/skills/simplify-code/SKILL.md",
    "dot_agents/skills/simplify-code/agents/openai.yaml",
    "dot_codex/AGENTS.md.tmpl",
    "dot_codex/agents/architect.toml",
    "dot_codex/agents/explorer.toml",
    "dot_codex/agents/repair.toml",
    "dot_codex/agents/review.toml",
    "dot_codex/agents/simplify.toml",
    "dot_codex/agents/verify.toml",
    "dot_codex/agents/visual.toml",
    "dot_codex/agents/worker.toml",
    "private_dot_claude/CLAUDE.md",
    "private_dot_claude/agents/simplify.md",
    "private_dot_config/private_opencode/agents/build.md",
    "private_dot_config/private_opencode/agents/plan.md",
    "private_dot_config/private_opencode/agents/review.md",
    "private_dot_config/private_opencode/agents/simplify.md",
    "private_dot_pi/agent/agent-tool-description.md",
    "private_dot_pi/agent/settings.json",
    "private_dot_pi/agent/subagents.json",
    "private_dot_pi/agent/agents/review.md",
    "private_dot_pi/agent/agents/simplify.md",
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

codex_simplify = tomllib.loads(
    (root / "dot_codex/agents/simplify.toml").read_text()
)
codex_review = tomllib.loads((root / "dot_codex/agents/review.toml").read_text())
codex_expected = {
    "architect": ("gpt-5.6-sol", "high", "read-only"),
    "explorer": ("gpt-5.6-luna", "low", "read-only"),
    "repair": ("gpt-5.6-sol", "high", "workspace-write"),
    "review": ("gpt-5.6-sol", "high", "read-only"),
    "simplify": ("gpt-5.6-terra", "medium", "workspace-write"),
    "verify": ("gpt-5.6-luna", "low", "workspace-write"),
    "visual": ("gpt-5.6-sol", "medium", "workspace-write"),
    "worker": ("gpt-5.6-terra", "medium", "workspace-write"),
}
codex_directory = root / "dot_codex/agents"
codex_agents = {path.stem for path in codex_directory.glob("*.toml")}
if codex_agents != set(codex_expected):
    raise SystemExit(
        f"Codex roster mismatch: expected {sorted(codex_expected)}, "
        f"found {sorted(codex_agents)}"
    )
for agent_name, expected in codex_expected.items():
    agent = tomllib.loads((codex_directory / f"{agent_name}.toml").read_text())
    actual = (
        agent.get("model"),
        agent.get("model_reasoning_effort"),
        agent.get("sandbox_mode"),
    )
    if actual != expected:
        raise SystemExit(
            f"Codex {agent_name} route mismatch: expected {expected}, found {actual}"
        )
    for field in ("name", "description", "developer_instructions"):
        if not agent.get(field):
            raise SystemExit(f"Codex {agent_name} is missing {field}")

codex_policy = (root / "dot_codex/AGENTS.md.tmpl").read_text()
if 'template "shared-agent-guidance.md"' not in codex_policy:
    raise SystemExit("Codex AGENTS.md must render the shared guidance template")
for agent_name in codex_expected:
    if f"`{agent_name}`" not in codex_policy:
        raise SystemExit(f"Codex routing policy does not name {agent_name}")

if (codex_simplify.get("model"), codex_simplify.get("model_reasoning_effort")) != (
    "gpt-5.6-terra",
    "medium",
):
    raise SystemExit("Codex simplify must remain Terra medium")
if codex_simplify.get("sandbox_mode") != "workspace-write":
    raise SystemExit("Codex simplify must remain write-enabled")
if (codex_review.get("model"), codex_review.get("model_reasoning_effort")) != (
    "gpt-5.6-sol",
    "high",
):
    raise SystemExit("Codex review must remain Sol high")
if codex_review.get("sandbox_mode") != "read-only":
    raise SystemExit("Codex review must remain read-only")

opencode_directory = root / "private_dot_config/private_opencode/agents"
opencode_agents = {path.stem for path in opencode_directory.glob("*.md")}
expected_primary = {"build", "plan"}
expected_children = {
    "architect",
    "explore",
    "implement-retry",
    "implement",
    "independent",
    "judgment",
    "review",
    "simplify",
    "verify",
    "visual",
}
if opencode_agents != expected_primary | expected_children:
    raise SystemExit(
        f"OpenCode roster mismatch: expected {sorted(expected_primary | expected_children)}, "
        f"found {sorted(opencode_agents)}"
    )

build = (opencode_directory / "build.md").read_text()
allowed_children = set(
    re.findall(
        r"action: subagent\n\s+resource: ([^*][^\n]*)\n\s+effect: allow",
        build,
    )
)
if allowed_children != expected_children:
    raise SystemExit(
        f"OpenCode build allowlist mismatch: expected {sorted(expected_children)}, "
        f"found {sorted(allowed_children)}"
    )
for agent_name in expected_children:
    if f"`{agent_name}`" not in build:
        raise SystemExit(f"OpenCode build routing policy does not name {agent_name}")
for contract in (
    "Before the first edit, classify the task.",
    "Keep one writer active in the shared checkout.",
    "run `simplify` once",
    "then run `review`",
):
    if contract not in build:
        raise SystemExit(f"OpenCode build lost routing contract: {contract}")

pi_directory = root / "private_dot_pi/agent/agents"
pi_agents = {path.stem for path in pi_directory.glob("*.md")}
if pi_agents != expected_children:
    raise SystemExit(
        f"Pi roster mismatch: expected {sorted(expected_children)}, found {sorted(pi_agents)}"
    )

pi_settings = json.loads((root / "private_dot_pi/agent/settings.json").read_text())
enabled_models = set(pi_settings["enabledModels"])
for path in pi_directory.glob("*.md"):
    text = path.read_text()
    model_match = re.search(r"(?m)^model: (.+)$", text)
    if not model_match or model_match.group(1) not in enabled_models:
        raise SystemExit(f"Pi agent model is not enabled: {path.name}")
    for field in ("prompt_mode: append", "inherit_context: false", "allowed_subagents: none"):
        if field not in text:
            raise SystemExit(f"Pi agent lost isolation setting {field!r}: {path.name}")

pi_subagents = json.loads((root / "private_dot_pi/agent/subagents.json").read_text())
if not pi_subagents.get("strictAgentFiles") or not pi_subagents.get("disableDefaultAgents"):
    raise SystemExit("Pi must use only the checked-in strict agent roster")
if pi_subagents.get("maxSubagentDepth") != 1:
    raise SystemExit("Pi subagent depth must remain 1")

claude_simplify = (root / "private_dot_claude/agents/simplify.md").read_text()
for field in ("model: sonnet", "effort: medium", "  - simplify-code"):
    if field not in claude_simplify:
        raise SystemExit(f"Claude simplify lost required setting: {field}")

tracked_agent_files = [
    *root.glob(".chezmoitemplates/*"),
    *root.glob("dot_agents/**/*.md"),
    *root.glob("dot_agents/**/*.tmpl"),
    *root.glob("dot_codex/**/*"),
    *root.glob("private_dot_claude/agents/*.md"),
    *root.glob("private_dot_config/private_opencode/agents/*.md"),
    *root.glob("private_dot_pi/agent/agents/*.md"),
]
for path in tracked_agent_files:
    if path.is_file() and re.search(r"/Users/[^/]+/", path.read_text()):
        raise SystemExit(f"Machine-specific home path found in {path}")

print("Agent routing source is complete and internally consistent.")
PY
