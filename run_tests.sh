#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
# A runtime error aborts only the test function it happens in; the suite keeps
# going and can still print PASS and exit 0. Any error line fails the run.
status=0
output="$(bash "${ROOT}/run_godot.sh" --headless --path "${ROOT}" -s res://tests/tower_tests.gd 2>&1)" || status=$?
printf '%s\n' "${output}"
if [ "${status}" -ne 0 ]; then
	exit "${status}"
fi
if printf '%s\n' "${output}" | grep -E 'SCRIPT ERROR|Parse Error|^ERROR:' >/dev/null; then
	echo "FAIL: Godot reported errors during the tests" >&2
	exit 1
fi
