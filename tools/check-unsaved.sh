#!/bin/bash
# check-unsaved - Check git repos for uncommitted/unpushed changes
#
# Config file: ~/.config/dots/tools/check-unsaved/config
# Format:
#   repo <path>   - check a specific git repo
#   scan <path>   - recursively scan directory for git repos
#   # comments and blank lines are ignored
#
# Example:
#   repo ~/.dots
#   scan ~/Work
#   scan ~/Personal

set -eu

CONFIG="$HOME/.config/dots/tools/check-unsaved/config"

if [[ ! -f "$CONFIG" ]]; then
	echo "Error: config file not found: $CONFIG" >&2
	echo "" >&2
	echo "Create it with repo and scan directives, e.g.:" >&2
	echo "  repo ~/.dots" >&2
	echo "  scan ~/Work" >&2
	exit 1
fi

RED='\e[1;31m'
BLUE='\e[1;34m'
NC='\e[0m'

check_project() {
	local project_path="$1"
	local name="${2:-$(basename "$1")}"

	cd "$project_path" || {
		echo -e "${RED}Error: Cannot cd into $project_path${NC}"
		return 1
	}

	local uncommitted unpushed ahead
	uncommitted=$(git status --porcelain 2>/dev/null)
	unpushed=$(git log --branches --not --remotes --oneline 2>/dev/null)
	ahead=$(git branch -v 2>/dev/null | grep '\[ahead' || true)

	if [[ -n "$uncommitted" ]] || [[ -n "$unpushed" ]] || [[ -n "$ahead" ]]; then
		echo -e "${BLUE}\n==> $name${NC}"

		if [[ -n "$uncommitted" ]]; then
			echo -e "${RED}--- Local Changes (Staged/Modified) ---${NC}"
			echo "$uncommitted"
		fi

		if [[ -n "$unpushed" ]]; then
			echo -e "${RED}--- Local Commits (Not Pushed) ---${NC}"
			echo "$unpushed"
		fi

		if [[ -n "$ahead" ]]; then
			echo -e "${RED}--- Ahead Branches ---${NC}"
			echo "$ahead"
		fi
	fi

	cd - >/dev/null
}

scan_directory() {
	local scan_path
	scan_path=$(eval echo "$1") # expand ~ and variables

	find "$scan_path" -type d -name '.git' -print0 | while IFS= read -r -d $'\0' git_dir; do
		local repo_path
		repo_path=$(dirname "$git_dir")
		local repo_name
		repo_name=$(echo "$repo_path" | sed -E "s!^$HOME/!~/!")
		check_project "$repo_path" "$repo_name"
	done
}

# Process config file
while IFS= read -r line; do
	# skip comments and blank lines
	[[ "$line" =~ ^[[:space:]]*# ]] && continue
	[[ -z "${line// /}" ]] && continue

	directive="${line%% *}"
	path="${line#* }"
	path=$(eval echo "$path") # expand ~ and variables

	case "$directive" in
	repo)
		check_project "$path"
		;;
	scan)
		scan_directory "$path"
		;;
	*)
		echo "Warning: unknown directive '$directive' in $CONFIG" >&2
		;;
	esac
done <"$CONFIG"
