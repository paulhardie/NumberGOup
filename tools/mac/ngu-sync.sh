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

# Godot runs the game from its import cache (.godot/, never committed), so a
# merge that adds a font, image or sound breaks the game until the new files
# are imported. Import once per commit, stamped, so a folder that is already
# current still catches up. Skipped while a Godot editor is open, which imports
# for itself; tried again next minute.
GODOT_BIN="${GODOT:-/Users/paulhardie/Downloads/Godot.app/Contents/MacOS/Godot}"
import_if_needed() {
	local stamp="$REPO/.godot/ngu-imported"
	local head
	head="$(git rev-parse HEAD)"
	if [ -f "$stamp" ] && [ "$(cat "$stamp")" = "$head" ]; then
		return 0
	fi
	if [ ! -x "$GODOT_BIN" ]; then
		log "no Godot at $GODOT_BIN, so new files are not imported"
		return 0
	fi
	if pgrep -f -- "--editor" >/dev/null 2>&1; then
		return 0
	fi
	# Through run_godot.sh, so Godot's user folder, and the real save, is never touched.
	if GODOT="$GODOT_BIN" bash "$REPO/run_godot.sh" --headless --path "$REPO" --import >/dev/null 2>&1; then
		mkdir -p "$REPO/.godot" && echo "$head" > "$stamp"
		log "imported $(git rev-parse --short HEAD)"
	else
		log "import failed at $(git rev-parse --short HEAD); will try again"
	fi
}

# Work an agent has pushed but nobody has merged isn't in the game, however
# finished it looks. Say so, once per change, for claude/ branches pushed in
# the last day, so waiting work is never mistaken for merged work (it was
# once: four changes sat on a branch with no pull request).
warn_unmerged() {
	git fetch --quiet --prune origin "+refs/heads/claude/*:refs/remotes/origin/claude/*" 2>/dev/null || return 0
	local seen="$REPO/.git/ngu-unmerged-seen"
	touch "$seen"
	local now
	now="$(date +%s)"
	git for-each-ref --format='%(refname:short) %(objectname) %(committerdate:unix)' refs/remotes/origin/claude/ |
		while read -r ref sha when; do
			[ $((now - when)) -lt 86400 ] || continue
			git merge-base --is-ancestor "$sha" "$target" && continue
			grep -qx "$sha" "$seen" && continue
			waiting="$(git rev-list --count "$target..$sha")"
			log "not in the game yet: ${ref#origin/} has $waiting change(s) waiting to be merged"
			notify "Not in the game yet: $waiting change(s) on ${ref#origin/} are waiting to be merged."
			echo "$sha" >> "$seen"
		done
}

cd "$REPO" 2>/dev/null || { log "no folder at $REPO"; exit 1; }
git fetch --quiet origin "$BRANCH" || { log "fetch failed (offline?)"; import_if_needed; exit 0; }
target="$(git rev-parse "origin/$BRANCH")"
warn_unmerged
if [ "$(git rev-parse HEAD)" = "$target" ] && [ -z "$(git status --porcelain)" ]; then
	import_if_needed
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
import_if_needed
notify "Updated: $subject. Reopen the game to play it."

# Keep the installed copy of this script current. mv is atomic, so the copy
# bash is running now is untouched.
installed="$HOME/.local/bin/ngu-sync.sh"
if [ -f "$installed" ] && ! cmp -s "$REPO/tools/mac/ngu-sync.sh" "$installed"; then
	cp "$REPO/tools/mac/ngu-sync.sh" "$installed.new" && chmod +x "$installed.new" && mv "$installed.new" "$installed"
fi
