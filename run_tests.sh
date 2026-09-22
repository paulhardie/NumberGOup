#!/usr/bin/env bash
set -euo pipefail
GODOT_BIN="${GODOT:-/Users/paulhardie/Downloads/Godot.app/Contents/MacOS/Godot}"
"${GODOT_BIN}" --headless --path "$(cd "$(dirname "$0")" && pwd)" -s res://tests/economy_tests.gd
