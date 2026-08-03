#!/bin/sh
set -eu

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
skills_root="$HOME/.agents/skills"

for command_name in npm ruby; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Public skill install requires $command_name." >&2
    exit 1
  fi
done

if [ ! -x "$repository_root/node_modules/.bin/dotagents" ]; then
  npm ci --ignore-scripts --prefix "$repository_root"
fi

dotagents="$repository_root/node_modules/.bin/dotagents"
"$dotagents" --user install
ruby "$repository_root/scripts/normalize-opencode-user-skills.rb" "$skills_root"
ruby "$repository_root/scripts/normalize-opencode-user-skills.rb" --check "$skills_root"

doctor_output=$("$dotagents" --user doctor 2>&1)
printf '%s\n' "$doctor_output"
if ! printf '%s\n' "$doctor_output" | grep -Fq 'All checks passed.'; then
  exit 1
fi
