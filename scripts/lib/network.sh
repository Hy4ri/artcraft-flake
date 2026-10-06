#!/usr/bin/env bash
#
# Shared network helpers for the update workflow.
# Source this from check-update.sh (or any CI script that fetches versions).
#
# What this encodes (learned from the Hy4ri flake fleet):
#   - fail fast on connect (--connect-timeout) instead of hanging 135s+
#   - retry transient errors (--retry 3 --retry-all-errors)
#   - cap total time (--max-time)
#   - capture the REAL error so the failure issue says something useful

# CI sets GITHUB_OUTPUT; default to stdout so scripts work locally too.
GITHUB_OUTPUT="${GITHUB_OUTPUT:-/dev/stdout}"

# Collects the last curl error for the failure report.
ERR_LOG="$(mktemp)"
trap 'rm -f "$ERR_LOG"' EXIT

# Write a failure reason and exit non-zero.
# The workflow captures this into its `fail_reason` output, which the
# report-failure job puts into the auto-opened issue.
die() {
  echo "fail_reason=$1" | tr -d '\n\r' >> "$GITHUB_OUTPUT"
  echo "$1" >&2
  exit 1
}

# Harden the fetch: returns 0 even on failure (empty stdout) so callers
# can inspect $ERR_LOG and die() with a rich reason.
fetch_url() {
  curl -fsSL --compressed --connect-timeout 10 --max-time 30 --retry 3 --retry-delay 3 --retry-all-errors "$1" 2>>"$ERR_LOG" || true
}

# GitHub API fetch with a 3-attempt retry loop (gh api output goes to stdout).
fetch_gh_api() {
  local out=""
  for i in 1 2 3; do
    if out=$(gh api "$@" 2>>"$ERR_LOG"); then
      printf '%s' "$out"
      return 0
    fi
    [ "$i" -lt 3 ] && sleep 5 || true
  done
  return 1
}
