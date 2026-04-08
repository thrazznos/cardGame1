#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

MODE="${1:-local}"

log() {
  printf '[preflight] %s\n' "$1"
}

fail() {
  printf '[preflight] ERROR: %s\n' "$1" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "required command not found: $1"
}

require_command git
require_command godot

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  fail "must be run inside a git repository"
fi

CURRENT_BRANCH="$(git branch --show-current)"
[ -n "$CURRENT_BRANCH" ] || fail "could not determine current branch"

log "mode: $MODE"
log "branch: $CURRENT_BRANCH"

if [ "$MODE" = "local" ]; then
  if [ "$CURRENT_BRANCH" = "main" ]; then
    fail "preflight must be run on a non-main branch; create or checkout a feature branch first"
  fi

  if [ -n "$(git status --porcelain)" ]; then
    fail "working tree is dirty; commit or stash changes before running preflight"
  fi

  log "fetching origin"
  git fetch origin

  log "rebasing current branch onto origin/main"
  git pull --rebase origin main
elif [ "$MODE" = "ci" ]; then
  log "fetching origin for behind-main check"
  git fetch origin

  if git merge-base --is-ancestor origin/main HEAD; then
    log "CI mode: checked-out revision includes origin/main"
  else
    printf '[preflight] WARNING: checked-out revision is behind origin/main; rerun local preflight on the branch before merge\n' >&2
  fi
else
  fail "unknown mode: $MODE (expected: local or ci)"
fi

log "running Godot headless parse check"
godot --headless --path . --quit

log "preflight passed"
