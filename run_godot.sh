#!/usr/bin/env bash
set -euo pipefail
# Godot resolves user://, where the owner's live save sits, under $HOME. Point it
# at a scratch folder so no run can touch that save. On macOS HOME is the only
# override Godot honours; the XDG_* variables are ignored.
#
# Which Godot: $GODOT if set; else the owner's Mac app; else `godot` on PATH; else
# the copy tools/install_godot_linux.sh puts in ~/.cache/number-go-up/godot.
ROOT="$(cd "$(dirname "$0")" && pwd)"
MAC_GODOT="/Users/paulhardie/Downloads/Godot.app/Contents/MacOS/Godot"
CACHED_GODOT="${GODOT_INSTALL_DIR:-${HOME}/.cache/number-go-up/godot}/godot-$(tr -d '[:space:]' < "${ROOT}/.godot-version")"
if [ -n "${GODOT:-}" ]; then
	GODOT_BIN="${GODOT}"
elif [ -x "${MAC_GODOT}" ]; then
	GODOT_BIN="${MAC_GODOT}"
elif command -v godot >/dev/null 2>&1; then
	GODOT_BIN="$(command -v godot)"
elif [ -x "${CACHED_GODOT}" ]; then
	GODOT_BIN="${CACHED_GODOT}"
else
	echo "run_godot.sh: no Godot found. Set GODOT, or on Linux run: bash tools/install_godot_linux.sh" >&2
	exit 127
fi
export HOME="${TMPDIR:-/tmp}/ngu-home"
exec "${GODOT_BIN}" "$@"
