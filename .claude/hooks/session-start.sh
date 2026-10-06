#!/usr/bin/env bash
# Claude Code cloud sessions: make the tests and tools runnable before work starts.
# Installs the pinned Godot (tools/install_godot_linux.sh), tells the session where
# it is, and imports the project once so the class cache is fresh (AGENTS.md: a
# stale .godot cache fails the tests on classes it can't find). Runs only in a
# cloud session, is safe to run again, and never touches the owner's real save
# (every Godot run goes through run_godot.sh).
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
	exit 0
fi

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "${ROOT}"

godot="$(bash tools/install_godot_linux.sh)"
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
	echo "export GODOT=\"${godot}\"" >> "${CLAUDE_ENV_FILE}"
fi

if [ ! -d .godot ]; then
	GODOT="${godot}" bash run_godot.sh --headless --path . --import >/dev/null 2>&1 || true
fi
echo "Godot ready: ${godot}"
