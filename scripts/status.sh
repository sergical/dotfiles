#!/bin/sh
# Answers three questions before and after a change to this repository:
# which machine is this, is the source in step with GitHub, and does this
# machine run what the source says. Read-only.
set -eu

cd "$(chezmoi source-path)"

profile=$(chezmoi execute-template \
  '{{ if hasKey . "profile_personal" }}{{ if .profile_personal }}personal{{ else }}work{{ end }}{{ else }}unknown{{ end }}')
flags=$(chezmoi execute-template \
  '{{ range $key, $value := . }}{{ if and (hasPrefix "profile_" $key) (eq (printf "%v" $value) "true") }}{{ trimPrefix "profile_" $key }} {{ end }}{{ end }}')
echo "Machine: $profile ($(uname -s)). Profile flags that are on: ${flags:-none}"

git fetch --quiet origin || echo "GitHub not reached; the numbers below may be old."
echo "Branch: $(git branch --show-current). Commits not on GitHub main: $(git rev-list --count origin/main..HEAD). Commits on GitHub main not here: $(git rev-list --count HEAD..origin/main)."

echo "Source edits not committed:"
git status --short | sed 's/^/  /'
echo "Files on this machine that differ from the source (chezmoi status; first letter: the file changed here, second: apply would change it):"
chezmoi status | sed 's/^/  /'
echo "Open pull requests:"
gh pr list --state open --json number,title,headRefName --template '{{ range . }}  #{{ .number }} {{ .title }} ({{ .headRefName }}){{ "\n" }}{{ end }}' 2>/dev/null || echo "  (gh not available)"
