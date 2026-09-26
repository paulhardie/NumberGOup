#!/bin/bash
# Keeps the owner's play folder identical to origin/<branch>, so whatever an
# agent has merged is what the game runs. launchd runs it every minute
# (tools/mac/install_sync.sh sets that up).
#
# It never loses anything: local edits and commits that aren't on origin are
# committed to a local-backup/<time> branch first, then the folder is moved to
# origin/<branch>. The old auto-updater skipped a dirty folder, and Godot's
# editor dirties it, so it could stall for good.
set -u
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
REPO="${NGU_REPO:?NGU_REPO must name the play folder}"
BRANCH="${NGU_BRANCH:-main}"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*"; }
notify() {
	command -v osascript >/dev/null && osascript -e "display notification \"$1\" with title \"Number Go Up\"" >/dev/null 2>&1
	return 0
}

cd "$REPO" 2>/dev/null || { log "no folder at $REPO"; exit 1; }
git fetch --quiet origin "$BRANCH" || { log "fetch failed (offline?)"; exit 0; }
target="$(git rev-parse "origin/$BRANCH")"
if [ "$(git rev-parse HEAD)" = "$target" ] && [ -z "$(git status --porcelain)" ]; then
	exit 0
fi

current="$(git rev-parse --abbrev-ref HEAD)"
if [ -n "$(git status --porcelain)" ] || ! git merge-base --is-ancestor HEAD "$target"; then
	backup="local-backup/$(date '+%Y%m%d-%H%M%S')-$(git rev-parse --short HEAD)"
	# If the backup can't be made, change nothing: losing work is worse than
	# a stale folder.
	if ! git switch --quiet -c "$backup"; then
		log "could not create $backup; left the folder as it was"
		exit 1
	fi
	git add -A
	if [ -n "$(git status --porcelain)" ]; then
		git -c user.name="ngu-sync" -c user.email="ngu-sync@localhost" commit --quiet --no-verify -m "Local changes kept by ngu-sync before updating to origin/$BRANCH"
	fi
	if [ -n "$(git status --porcelain)" ]; then
		log "could not commit local changes to $backup; left the folder there"
		exit 1
	fi
	log "kept local state from $current on $backup"
fi
git switch --quiet -C "$BRANCH" "$target"
git branch --quiet --set-upstream-to "origin/$BRANCH" "$BRANCH"
subject="$(git log -1 --format=%s)"
log "updated to $(git rev-parse --short HEAD): $subject"
notify "Updated: $subject. Reopen the game to play it."

# Keep the installed copy of this script current. mv is atomic, so the copy
# bash is running now is untouched.
installed="$HOME/.local/bin/ngu-sync.sh"
if [ -f "$installed" ] && ! cmp -s "$REPO/tools/mac/ngu-sync.sh" "$installed"; then
	cp "$REPO/tools/mac/ngu-sync.sh" "$installed.new" && chmod +x "$installed.new" && mv "$installed.new" "$installed"
fi
