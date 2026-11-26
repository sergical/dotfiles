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
    .chezmoi.toml.tmpl|.chezmoiexternal.toml|.chezmoiignore.tmpl|.gitignore|AGENTS.md|CLAUDE.md|LICENSE|README.md|SECURITY.md|package.json|package-lock.json) ;;
    .chezmoitemplates/shared-agent-guidance.md) ;;
    .github/workflows/validate.yml|.githooks/pre-commit|.githooks/prepare-commit-msg) ;;
    run_onchange_after_set-git-hooks.sh.tmpl) ;;
    docs/agent-routing.md|docs/architecture.md|docs/context-loading.md|docs/profiles.md|docs/security.md|docs/skills.md) ;;
    scripts/capture.sh|scripts/check-agent-routing.sh|scripts/check-source.sh|scripts/status.sh|scripts/install-public-skills.sh|scripts/normalize-opencode-user-skills.rb|scripts/test-t3-fork-install-pending.sh) ;;
    scripts/test-t3-fork-sync-retry.sh) ;;
    dot_Brewfile|dot_gitconfig.tmpl|dot_zprofile|dot_zshrc.tmpl|modify_dot_zshenv) ;;
    dot_cargo/config.toml) ;;
    private_dot_npmrc.tmpl) ;;
    dot_agents/AGENTS.md.tmpl|dot_agents/agents.toml) ;;
    dot_agents/private_mcp.json.tmpl) ;;
    dot_agents/hooks/executable_ui-review-reminder.py|dot_agents/hooks/executable_machine-load-gate.py) ;;
    dot_agents/skills/simplify-code/SKILL.md|dot_agents/skills/simplify-code/agents/openai.yaml) ;;
    dot_agents/skills/babysit-pr/SKILL.md|dot_agents/skills/dev-servers/SKILL.md|dot_agents/skills/dev-servers/executable_list-blocks.sh|dot_agents/skills/diff-review/SKILL.md.tmpl|dot_agents/skills/full-send/SKILL.md|dot_agents/skills/full-stop/SKILL.md|dot_agents/skills/pr-body/SKILL.md.tmpl|dot_agents/skills/video-context/SKILL.md|dot_agents/skills/testing/SKILL.md.tmpl|dot_agents/skills/test-audit/SKILL.md.tmpl|dot_agents/skills/test-audit/agents/openai.yaml) ;;
    dot_gemini/symlink_AGENTS.md|dot_gemini/config/symlink_skills|dot_gemini/config/modify_private_mcp_config.json) ;;
    dot_codex/symlink_AGENTS.md|dot_codex/hooks.json.tmpl|dot_codex/modify_private_config.toml) ;;
    private_dot_cursor/rules/shared-agent-guidance.mdc.tmpl|private_dot_cursor/hooks.json) ;;
    private_dot_local/private_bin/executable_skill-inventory|private_dot_local/private_bin/executable_t3-fork-sync) ;;
    private_dot_local/private_bin/executable_t3-fork-install-pending|private_Library/LaunchAgents/local.t3-fork-sync.plist.tmpl) ;;
    private_dot_local/private_bin/executable_storage-keeper|private_Library/LaunchAgents/local.storage-keeper.plist.tmpl) ;;
    private_dot_aws/private_config.tmpl) ;;
    private_dot_claude/private_settings.json.tmpl|private_dot_claude/CLAUDE.md) ;;
    private_dot_claude/bin/executable_ccstatusline-autocompact) ;;
    private_dot_config/ccstatusline/settings.json) ;;
    private_dot_config/private_cmux/private_cmux.json) ;;
    private_dot_config/private_cspell/serge-makes-up-words.txt) ;;
    private_dot_config/private_gh/private_config.yml) ;;
    private_dot_config/private_git/ignore) ;;
    private_dot_config/private_opencode/symlink_AGENTS.md) ;;
    private_dot_config/private_opencode/private_opencode.json.tmpl|private_dot_config/private_opencode/private_cli.json) ;;
    private_dot_config/private_opencode/agents/plan.md) ;;
    private_dot_pi/agent/settings.json.tmpl|private_dot_pi/agent/symlink_AGENTS.md) ;;
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
