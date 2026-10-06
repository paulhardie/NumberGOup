#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
# A runtime error aborts only the test function it happens in; the suite keeps
# going and can still print PASS and exit 0. Any error line fails the run.
for suite in tower_tests foundation_tests save_fixture_tests; do
status=0
output="$(bash "${ROOT}/run_godot.sh" --headless --path "${ROOT}" -s "res://tests/${suite}.gd" 2>&1)" || status=$?
printf '%s\n' "${output}"
if [ "${status}" -ne 0 ]; then
	exit "${status}"
fi
if printf '%s\n' "${output}" | grep -E 'SCRIPT ERROR|Parse Error|^ERROR:' >/dev/null; then
	echo "FAIL: Godot reported errors during the tests" >&2
	exit 1
fi
done
# The balance reporter has its own contracts (sample pairing, stopped runs and
# explicit baseline replacement), without running the long measurement suite.
python3 -m unittest discover -s "${ROOT}/tests" -p 'test_*.py'
