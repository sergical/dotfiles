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
  case "$source_path" in
    .chezmoi.toml.tmpl|.chezmoiignore.tmpl|.gitignore|AGENTS.md|LICENSE|README.md|SECURITY.md|package.json|package-lock.json) ;;
    .github/workflows/validate.yml|.githooks/pre-commit) ;;
    docs/architecture.md|docs/profiles.md|docs/security.md) ;;
    scripts/check-source.sh|scripts/install-public-skills.sh|scripts/normalize-opencode-user-skills.rb) ;;
    dot_Brewfile|dot_gitconfig.tmpl|dot_zprofile|dot_zshrc.tmpl) ;;
    dot_agents/AGENTS.md|dot_agents/agents.toml) ;;
    private_dot_aws/private_config.tmpl) ;;
    private_dot_claude/private_settings.json|private_dot_claude/symlink_CLAUDE.md) ;;
    private_dot_config/private_cmux/private_cmux.json.tmpl) ;;
    private_dot_config/private_cspell/serge-makes-up-words.txt) ;;
    private_dot_config/private_gh/private_config.yml) ;;
    private_dot_config/private_git/ignore) ;;
    private_dot_config/private_opencode/symlink_AGENTS.md) ;;
    private_dot_pi/agent/symlink_AGENTS.md) ;;
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
