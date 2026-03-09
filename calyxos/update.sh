#!/usr/bin/env bash

set -e
set -o pipefail

# CalyxOS branches to track
branches=(
  "android16"
  "android15-qpr2"
  "android15"
  "android14"
)

echo "Branches to fetch: ${branches[*]}"

for branch in "${branches[@]}"; do
  mkdir -p "$branch"

  if [ ! -e "$branch/repo.lock" ]; then
    echo "No lockfile for $branch yet."
    # Copy from first existing lockfile as a starting point
    for existing_branch in "${branches[@]}"; do
      if [ -e "$existing_branch/repo.lock" ]; then
        echo "Copying from existing branch $existing_branch."
        cp "$existing_branch/repo.lock" "$branch/repo.lock"
        break
      fi
    done
  fi

  echo "Fetching lockfile for branch $branch..."
  repo-tool fetch -r "$branch" https://gitlab.com/CalyxOS/platform_manifest "$branch/repo.lock"
done

echo "Deleting unused lockfiles..."
for lockfile in */repo.lock; do
  present=0
  for branch in "${branches[@]}"; do
    if [ "$branch/repo.lock" = "$lockfile" ]; then
      present=1
    fi
  done
  if [ $present -eq 0 ]; then
    echo "Deleting $lockfile..."
    rm -r "$(dirname "$lockfile")"
  fi
done

echo "Done!"
