#!/usr/bin/env bash
#
# check-update.sh — checks every Crafting App against its latest GitHub release.
# Contract (see README): writes update_needed / version to $GITHUB_OUTPUT, or die().
# `version` is a human summary of what changed; update-version.sh re-syncs ALL apps.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/network.sh"

OWNER="storytold"
CHANGED=""

for app in $(jq -r 'keys[]' version.json); do
  latest=""
  if ! latest=$(fetch_gh_api "repos/$OWNER/$app/releases/latest" --jq '.tag_name | ltrimstr("v")'); then
    die "Could not fetch latest $app version from GitHub API after 3 attempts. Last error: $(tail -n 1 "$ERR_LOG" 2>/dev/null || echo 'unknown')"
  fi
  [ -n "$latest" ] || die "GitHub API returned an empty version for $app."
  current=$(jq -r --arg a "$app" '.[$a].version' version.json)
  echo "$app: current=$current latest=$latest"
  if [ "$latest" != "$current" ]; then
    CHANGED="${CHANGED:+$CHANGED,}$app-$latest"
  fi
done

if [ -n "$CHANGED" ]; then
  echo "update_needed=true" >> "$GITHUB_OUTPUT"
  echo "version=$CHANGED" >> "$GITHUB_OUTPUT"
else
  echo "update_needed=false" >> "$GITHUB_OUTPUT"
fi
