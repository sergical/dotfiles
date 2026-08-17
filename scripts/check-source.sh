#!/bin/sh
set -eu

repository_root=$(git rev-parse --show-toplevel)
cd "$repository_root"

scan_mode=${1:-all}
case "$scan_mode" in
  all)
    source_paths=$(git -c core.quotePath=false ls-files --cached --others --exclude-standard)
    ;;
  staged)
    source_paths=$(git -c core.quotePath=false diff --cached --name-only --diff-filter=ACMR)
    ;;
  paths)
    source_paths=$(git -c core.quotePath=false ls-files --cached --others --exclude-standard)
    ;;
  *)
    echo "Usage: scripts/check-source.sh [all|staged|paths]" >&2
    exit 2
    ;;
esac

rejected_paths=""
while IFS= read -r source_path; do
  [ -n "$source_path" ] || continue
  [ -e "$source_path" ] || continue
  case "$source_path" in
    .chezmoi.toml.tmpl|.chezmoiignore.tmpl|.gitignore|AGENTS.md|LICENSE|README.md|SECURITY.md|package.json|package-lock.json) ;;
    .chezmoitemplates/shared-agent-guidance.md) ;;
    .github/workflows/validate.yml|.githooks/pre-commit) ;;
    docs/agent-routing.md|docs/architecture.md|docs/context-loading.md|docs/profiles.md|docs/security.md|docs/skills.md) ;;
    scripts/capture.sh|scripts/check-agent-routing.sh|scripts/check-source.sh|scripts/install-public-skills.sh|scripts/normalize-opencode-user-skills.rb) ;;
    dot_Brewfile|dot_gitconfig.tmpl|dot_zprofile|dot_zshrc.tmpl) ;;
    dot_agents/AGENTS.md.tmpl|dot_agents/agents.toml) ;;
    dot_agents/skills/simplify-code/SKILL.md|dot_agents/skills/simplify-code/agents/openai.yaml) ;;
    dot_codex/AGENTS.md.tmpl) ;;
    dot_codex/agents/architect.toml|dot_codex/agents/explorer.toml|dot_codex/agents/repair.toml|dot_codex/agents/review.toml|dot_codex/agents/simplify.toml|dot_codex/agents/verify.toml|dot_codex/agents/visual.toml|dot_codex/agents/worker.toml) ;;
    private_dot_local/private_bin/executable_skill-inventory) ;;
    dot_plannotator/config.json) ;;
    private_dot_aws/private_config.tmpl) ;;
    private_dot_claude/private_settings.json.tmpl|private_dot_claude/CLAUDE.md) ;;
    private_dot_claude/agents/Explore.md|private_dot_claude/agents/diagram.md|private_dot_claude/agents/digest.md|private_dot_claude/agents/implement.md|private_dot_claude/agents/simplify.md|private_dot_claude/agents/verify.md) ;;
    private_dot_claude/bin/executable_ccstatusline-autocompact) ;;
    private_dot_config/ccstatusline/settings.json) ;;
    private_dot_config/private_cmux/private_cmux.json) ;;
    private_dot_config/private_cspell/serge-makes-up-words.txt) ;;
    private_dot_config/private_gh/private_config.yml) ;;
    private_dot_config/private_git/ignore) ;;
    private_dot_config/private_opencode/symlink_AGENTS.md) ;;
    private_dot_config/private_opencode/private_opencode.json.tmpl|private_dot_config/private_opencode/private_cli.json) ;;
    private_dot_config/private_opencode/agents/architect.md|private_dot_config/private_opencode/agents/build.md|private_dot_config/private_opencode/agents/explore.md|private_dot_config/private_opencode/agents/implement-retry.md|private_dot_config/private_opencode/agents/implement.md|private_dot_config/private_opencode/agents/independent.md|private_dot_config/private_opencode/agents/judgment.md|private_dot_config/private_opencode/agents/plan.md|private_dot_config/private_opencode/agents/review.md|private_dot_config/private_opencode/agents/simplify.md|private_dot_config/private_opencode/agents/verify.md|private_dot_config/private_opencode/agents/visual.md) ;;
    private_dot_pi/agent/settings.json|private_dot_pi/agent/subagents.json|private_dot_pi/agent/symlink_AGENTS.md) ;;
    private_dot_pi/agent/agent-tool-description.md) ;;
    private_dot_pi/agent/agents/architect.md|private_dot_pi/agent/agents/explore.md|private_dot_pi/agent/agents/implement-retry.md|private_dot_pi/agent/agents/implement.md|private_dot_pi/agent/agents/independent.md|private_dot_pi/agent/agents/judgment.md|private_dot_pi/agent/agents/review.md|private_dot_pi/agent/agents/simplify.md|private_dot_pi/agent/agents/verify.md|private_dot_pi/agent/agents/visual.md) ;;
    private_Library/private_Application\ Support/private_Cursor/private_User/keybindings.json) ;;
    private_Library/private_Application\ Support/private_Cursor/private_User/settings.json) ;;
    *) rejected_paths="${rejected_paths}${rejected_paths:+
}${source_path}" ;;
  esac
done <<EOF
$source_paths
EOF

if [ -n "$rejected_paths" ]; then
  echo "Public source allowlist rejected:" >&2
  printf '  %s\n' "$rejected_paths" >&2
  exit 1
fi

if [ "$scan_mode" = paths ]; then
  exit 0
fi

if ! command -v gitleaks >/dev/null 2>&1; then
  echo "Source check requires gitleaks (brew install gitleaks)." >&2
  exit 1
fi

if [ "$scan_mode" = staged ]; then
  exec gitleaks git --staged --redact=100 --no-banner .
fi

gitleaks dir --redact=100 --no-banner .
gitleaks git --redact=100 --no-banner .
