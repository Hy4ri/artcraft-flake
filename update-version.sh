#!/usr/bin/env bash
#
# update-version.sh — re-sync version.json with the latest release of every app.
# Hashes come from each release's SHA256SUMS.txt (no archive downloads needed).
# Usage: ./update-version.sh [ignored]   (the workflow passes a changelog string)

set -euo pipefail

OWNER="storytold"
CURL=(curl -fsSL --connect-timeout 10 --max-time 120 --retry 3 --retry-delay 3 --retry-all-errors)
declare -A ARCH=( [x86_64-linux]=x86_64 [aarch64-linux]=aarch64 )

tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
cp version.json "$tmp"

for app in $(jq -r 'keys[]' version.json); do
  tag=$("${CURL[@]}" -H "Authorization: Bearer ${GH_TOKEN:-${GITHUB_TOKEN:-}}" \
        "https://api.github.com/repos/$OWNER/$app/releases/latest" | jq -r '.tag_name')
  [ -n "$tag" ] && [ "$tag" != null ] || { echo "Error: no release for $app" >&2; exit 1; }
  version="${tag#v}"
  sums=$("${CURL[@]}" "https://github.com/$OWNER/$app/releases/download/$tag/SHA256SUMS.txt")
  echo "$app -> $version"
  for sys in "${!ARCH[@]}"; do
    hex=$(awk -v f="$app-$version-linux-${ARCH[$sys]}.tar.gz" '$2==f {print $1}' <<<"$sums")
    [ -n "$hex" ] || { echo "Error: no checksum for $app $sys" >&2; exit 1; }
    sri=$(nix hash convert --hash-algo sha256 --to sri "$hex")
    jq --arg a "$app" --arg v "$version" --arg s "$sys" --arg h "$sri" \
       '.[$a].version=$v | .[$a].hashes[$s]=$h' "$tmp" > "$tmp.new" && mv "$tmp.new" "$tmp"
  done
done

jq -S . "$tmp" > version.json
echo "Done."
