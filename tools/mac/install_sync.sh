#!/bin/bash
# Makes a folder on this Mac the play folder and keeps it in step with GitHub:
#
#   bash install_sync.sh ~/Desktop/NumberGOup [branch]
#
# If the folder isn't a git checkout of the game, it is renamed to
# "<folder>-old-<time>" (nothing is deleted) and a fresh clone takes its place.
# Then a launchd job (com.paulhardie.ngu-sync) runs tools/mac/ngu-sync.sh every
# minute, which moves the folder to origin/<branch> (default main), keeping any
# local changes on a local-backup/ branch first. Log: ~/Library/Logs/ngu-sync.log
#
# To stop it: launchctl bootout gui/$(id -u)/com.paulhardie.ngu-sync
set -eu
FOLDER_ARG="${1:?name the play folder, e.g. ~/Desktop/NumberGOup}"
BRANCH="${2:-main}"
LABEL="com.paulhardie.ngu-sync"
URL="https://github.com/paulhardie/NumberGOup.git"
[ -d "$HOME/NumberGOup-main/.git" ] && URL="$(git -C "$HOME/NumberGOup-main" remote get-url origin)"

FOLDER="$(cd "$(dirname "$FOLDER_ARG")" && pwd)/$(basename "$FOLDER_ARG")"
# It must be a checkout of this game in its own right, not a folder that
# happens to sit inside some other repository.
is_game_checkout() {
	[ "$(git -C "$1" rev-parse --show-toplevel 2>/dev/null)" = "$1" ] &&
		git -C "$1" remote get-url origin 2>/dev/null | grep -qi "numbergoup"
}
if [ -e "$FOLDER" ] && ! is_game_checkout "$FOLDER"; then
	aside="$FOLDER-old-$(date '+%Y%m%d-%H%M%S')"
	mv "$FOLDER" "$aside"
	echo "Not a git checkout of the game, so moved it to $aside"
fi
if [ ! -e "$FOLDER" ]; then
	git clone --quiet "$URL" "$FOLDER"
	echo "Cloned the game into $FOLDER"
fi

mkdir -p "$HOME/.local/bin" "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
git -C "$FOLDER" fetch --quiet origin "$BRANCH"
git -C "$FOLDER" show "origin/$BRANCH:tools/mac/ngu-sync.sh" > "$HOME/.local/bin/ngu-sync.sh"
chmod +x "$HOME/.local/bin/ngu-sync.sh"

PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
cat > "$PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key><string>$LABEL</string>
	<key>ProgramArguments</key>
	<array><string>/bin/bash</string><string>$HOME/.local/bin/ngu-sync.sh</string></array>
	<key>EnvironmentVariables</key>
	<dict>
		<key>NGU_REPO</key><string>$FOLDER</string>
		<key>NGU_BRANCH</key><string>$BRANCH</string>
	</dict>
	<key>StartInterval</key><integer>60</integer>
	<key>RunAtLoad</key><true/>
	<key>StandardOutPath</key><string>$HOME/Library/Logs/ngu-sync.log</string>
	<key>StandardErrorPath</key><string>$HOME/Library/Logs/ngu-sync.log</string>
</dict>
</plist>
PLIST

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
NGU_REPO="$FOLDER" NGU_BRANCH="$BRANCH" bash "$HOME/.local/bin/ngu-sync.sh" || true
echo
echo "Play folder: $FOLDER"
git -C "$FOLDER" log -1 --format='Now on %h: %s'
echo "It checks GitHub every minute. Log: ~/Library/Logs/ngu-sync.log"
