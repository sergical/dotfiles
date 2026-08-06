#!/bin/sh
set -eu

# Capture target-side drift back into the Chezmoi source repository:
# re-add the given target paths, verify them against the public-source
# allowlist and gitleaks, commit, and push. The inverse of dotsync's
# render direction. Paths are explicit by policy - never blanket re-add.

usage() {
  echo "Usage: scripts/capture.sh [-m commit-message] TARGET_PATH..." >&2
  exit 2
}

commit_message=""
while getopts m: option; do
  case "$option" in
    m) commit_message=$OPTARG ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))
[ "$#" -ge 1 ] || usage

repository_root=$(chezmoi source-path)
cd "$repository_root"

if [ -n "$(git status --porcelain)" ]; then
  echo "Refusing to capture into a dirty source repository; commit or stash first." >&2
  exit 1
fi

for target_path in "$@"; do
  chezmoi re-add "$target_path"
done

if [ -z "$(git status --porcelain)" ]; then
  echo "No drift captured; source already matches the given paths."
  exit 0
fi

git add -A
git --no-pager diff --cached --stat
scripts/check-source.sh staged

if [ -z "$commit_message" ]; then
  commit_message="Capture $(basename "$1") drift"
fi

git commit -m "$commit_message"
git push
echo "Captured, verified, and pushed."
