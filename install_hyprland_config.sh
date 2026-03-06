#!/usr/bin/env bash
# install_hyprland_config.sh
#
# Installs Hyprland config from .dots/config/hypr into .dots/live/hypr,
# symlinks ~/.config/hypr → .dots/live/hypr, and provides a safe
# 10-second rollback window before committing.
#
# live/hypr is an independent git repo (gitignored by .dots) so omarchy
# migrations and other tools can modify it freely. After an upgrade, use
# 'git diff' in live/hypr to review changes, then cherry-pick into config/hypr.

set -ue

root_path=$(cd "$(dirname "$0")" && pwd)
source_hypr="$root_path/config/hypr"
live_hypr="$root_path/live/hypr"
config_hypr="$HOME/.config/hypr"
timeout=10

# -------
# helpers
# -------

abort() {
	echo "Error: $1" >&2
	exit 1
}

dots_short_hash() {
	git -C "$root_path" rev-parse --short HEAD 2>/dev/null || echo "unknown"
}

# --------
# step 1: init live/hypr as a git repo
# --------

echo "Checking live/hypr..." >&2

if [[ ! -d "$live_hypr" ]]; then
	echo "Initializing live/hypr..." >&2
	mkdir -p "$live_hypr"
	git init "$live_hypr" >/dev/null

	if [[ -e "$config_hypr" || -L "$config_hypr" ]]; then
		echo "Snapshotting existing ~/.config/hypr into live/hypr..." >&2
		cp -rL "$config_hypr/." "$live_hypr/"
		git -C "$live_hypr" add .
		git -C "$live_hypr" commit -m "initial: snapshot from ~/.config/hypr" >/dev/null
		echo "Initial commit created from existing config." >&2
	else
		git -C "$live_hypr" commit --allow-empty -m "initial commit" >/dev/null
		echo "Empty initial commit created." >&2
	fi
elif [[ ! -d "$live_hypr/.git" ]]; then
	abort "live/hypr exists but is not a git repo. Remove or resolve manually."
else
	echo "live/hypr already initialized." >&2
fi

# --------
# step 2: verify ~/.config/hypr symlink
# --------

echo "Verifying ~/.config/hypr symlink..." >&2

if [[ -L "$config_hypr" ]]; then
	current_target=$(readlink -f "$config_hypr")
	expected_target=$(readlink -f "$live_hypr")
	if [[ "$current_target" == "$expected_target" ]]; then
		echo "Symlink is correct." >&2
	else
		echo "Symlink points elsewhere ($current_target). Updating..." >&2
		rm "$config_hypr"
		ln -s "$live_hypr" "$config_hypr"
		echo "Symlink updated." >&2
	fi
elif [[ -d "$config_hypr" ]]; then
	abort "~/.config/hypr is a real directory, not a symlink.
  Back up or remove it manually before re-running:
    mv ~/.config/hypr ~/.config/hypr.bak"
else
	echo "Creating ~/.config/hypr symlink..." >&2
	mkdir -p "$(dirname "$config_hypr")"
	ln -s "$live_hypr" "$config_hypr"
	echo "Symlink created." >&2
fi

# --------
# step 3: dirty check
# --------

echo "Checking live/hypr for uncommitted changes..." >&2

if [[ -n "$(git -C "$live_hypr" status --porcelain)" ]]; then
	abort "Uncommitted changes detected in live/hypr.
  Review with:
    cd $live_hypr && git diff
  Commit or discard before re-running:
    git -C $live_hypr add . && git -C $live_hypr commit -m 'your message'
    git -C $live_hypr checkout ."
fi

echo "live/hypr is clean." >&2

# --------
# step 4: copy config/hypr → live/hypr
# --------

echo "Copying config/hypr into live/hypr..." >&2
cp -r "$source_hypr/." "$live_hypr/"
echo "Copy complete." >&2

# --------
# step 5: reload hyprland
# --------

echo "Reloading Hyprland..." >&2
hyprctl reload >/dev/null 2>&1 || true

# --------
# step 6: countdown - press Y to keep, else revert
# --------

echo "" >&2
echo "Config applied. Press Y within ${timeout}s to keep, or it will auto-revert." >&2
echo "" >&2

confirmed=false
for ((i = timeout; i > 0; i--)); do
	printf "\r  Reverting in %2ds... (press Y to keep)  " "$i" >&2
	if read -t 1 -n 1 -rs key 2>/dev/null; then
		if [[ "$key" == [Yy] ]]; then
			confirmed=true
		fi
		break
	fi
done

echo "" >&2

if [[ "$confirmed" == true ]]; then
	hash=$(dots_short_hash)
	echo "Config kept. Review changes and commit when ready:" >&2
	echo "" >&2
	git -C "$live_hypr" status --short >&2
	echo "" >&2
	echo "  cd $live_hypr" >&2
	echo "  git diff" >&2
	echo "  git add . && git commit -m \"install from .dots @ $hash\"" >&2
	echo "" >&2
else
	echo "No confirmation. Reverting..." >&2
	git -C "$live_hypr" checkout . >/dev/null
	hyprctl reload >/dev/null 2>&1 || true
	echo "Reverted to previous config." >&2
	exit 1
fi
