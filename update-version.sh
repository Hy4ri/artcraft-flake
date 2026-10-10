#!/usr/bin/env bash
#
# Fetches the latest release versions and hashes for all apps listed in version.json
# and updates the file accordingly.

set -euo pipefail

OWNER="storytold"
CURL=(curl -fsSL --connect-timeout 10 --max-time 120 --retry 3 --retry-delay 3 --retry-all-errors)
declare -A ARCH=( [x86_64-linux]=x86_64 [aarch64-linux]=aarch64 )

if [ -n "${GH_TOKEN:-${GITHUB_TOKEN:-}}" ]; then
  CURL+=(-H "Authorization: Bearer ${GH_TOKEN:-${GITHUB_TOKEN:-}}")
fi

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
cp version.json "$tmp"

for app in $(jq -r 'keys[]' version.json); do
  # Get the latest release tag from GitHub API
  tag=$("${CURL[@]}" "https://api.github.com/repos/$OWNER/$app/releases/latest" | jq -r '.tag_name')
  
  [ -n "$tag" ] && [ "$tag" != null ] || { echo "Error: no release for $app" >&2; exit 1; }
  
  version="${tag#v}"
  
  # Fetch SHA256 hashes straight from the release assets
  sums=$("${CURL[@]}" "https://github.com/$OWNER/$app/releases/download/$tag/SHA256SUMS.txt")
  
  echo "Updating $app -> $version"
  
  for sys in "${!ARCH[@]}"; do
    hex=$(awk -v f="$app-$version-linux-${ARCH[$sys]}.tar.gz" '$2==f {print $1}' <<<"$sums")
    [ -n "$hex" ] || { echo "Error: no checksum for $app $sys" >&2; exit 1; }
    
    # Convert hex hash to SRI format required by Nix
    if command -v nix >/dev/null 2>&1; then
      sri=$(nix hash convert --hash-algo sha256 --to sri "$hex")
    else
      sri=$(python3 -c 'import sys, binascii; print("sha256-" + binascii.b2a_base64(binascii.unhexlify(sys.argv[1].strip())).decode().strip())' "$hex")
    fi
    
    # Update version.json
    jq --arg a "$app" --arg v "$version" --arg s "$sys" --arg h "$sri" \
       '.[$a].version=$v | .[$a].hashes[$s]=$h' "$tmp" > "$tmp.new" && mv "$tmp.new" "$tmp"
  done
done

# Format and save the final JSON file
jq -S . "$tmp" > version.json
echo "Done."
