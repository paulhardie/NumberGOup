#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
bash "${ROOT}/run_godot.sh" --headless --path "${ROOT}" -s res://tests/economy_tests.gd
