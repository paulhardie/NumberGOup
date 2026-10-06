#!/usr/bin/env bash
# Installs the Godot this project is pinned to (.godot-version) for Linux, with
# its release checksum verified, and prints the binary's path as the last line of
# stdout. CI and Claude Code cloud sessions both use it, so the pin lives in one
# place. Safe to run again: it does nothing if that version is already there.
#
#   bash tools/install_godot_linux.sh [folder]
#
# The folder defaults to $GODOT_INSTALL_DIR, then ~/.cache/number-go-up/godot.
# run_godot.sh looks there too, so after this nothing else needs setting.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${GODOT_VERSION:-$(tr -d '[:space:]' < "${ROOT}/.godot-version")}"
DEST="${1:-${GODOT_INSTALL_DIR:-${HOME}/.cache/number-go-up/godot}}"
BIN="${DEST}/godot-${VERSION}"

if [ -x "${BIN}" ]; then
	echo "Godot ${VERSION} is already at ${BIN}" >&2
	echo "${BIN}"
	exit 0
fi

zip="Godot_v${VERSION}_linux.x86_64.zip"
base="https://github.com/godotengine/godot/releases/download/${VERSION}"
work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT
mkdir -p "${DEST}"
echo "Downloading Godot ${VERSION}…" >&2
(
	cd "${work}"
	curl -fsSLO "${base}/${zip}"
	curl -fsSLO "${base}/SHA512-SUMS.txt"
	expected="$(grep -F "  ${zip}" SHA512-SUMS.txt || true)"
	test -n "${expected}" || { echo "No checksum entry for ${zip}" >&2; exit 1; }
	printf '%s\n' "${expected}" | sha512sum -c - >&2
	unzip -q "${zip}"
	mv "Godot_v${VERSION}_linux.x86_64" "${BIN}.tmp"
)
chmod +x "${BIN}.tmp"
mv "${BIN}.tmp" "${BIN}"
echo "Installed Godot ${VERSION} at ${BIN}" >&2
echo "${BIN}"
