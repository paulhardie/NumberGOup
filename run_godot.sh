#!/usr/bin/env bash
set -euo pipefail
# Godot resolves user://, where the owner's live save sits, under $HOME. Point it
# at a scratch folder so no run can touch that save. On macOS HOME is the only
# override Godot honours; the XDG_* variables are ignored.
GODOT_BIN="${GODOT:-/Users/paulhardie/Downloads/Godot.app/Contents/MacOS/Godot}"
export HOME="${TMPDIR:-/tmp}/ngu-home"
exec "${GODOT_BIN}" "$@"
