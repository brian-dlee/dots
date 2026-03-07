#!/usr/bin/env bash
# install_tools.sh
#
# Installs all tools in tools/ to ~/.local/bin based on file type:
#
#   tools/*.sh          - strip .sh, symlink to ~/.local/bin/<name>
#   tools/*/main.go     - go build directory, install binary as ~/.local/bin/<dirname>

set -ue

root_path=$(cd "$(dirname "$0")" && pwd)
tools_dir="$root_path/tools"
bin_dir="$HOME/.local/bin"

mkdir -p "$bin_dir"

install_symlink() {
	local src="$1"
	local name="$2"
	local dest="$bin_dir/$name"

	if [[ -L "$dest" ]] && [[ "$(readlink -f "$dest")" == "$src" ]]; then
		echo "  $name is up to date" >&2
	else
		rm -f "$dest"
		ln -s "$src" "$dest"
		echo "  Installed $name -> $dest" >&2
	fi
}

install_go() {
	local dir="$1"
	local name="$2"
	local dest="$bin_dir/$name"

	echo "  Building $name..." >&2
	go build -o "$dest" "$dir"
	echo "  Installed $name -> $dest" >&2
}

# *.sh files → strip .sh, symlink
echo "Installing shell tools..." >&2
for src in "$tools_dir"/*.sh; do
	[[ -f "$src" ]] || continue
	name=$(basename "$src" .sh)
	install_symlink "$src" "$name"
done

# */main.go files → go build
echo "Installing Go tools..." >&2
for main in "$tools_dir"/*/main.go; do
	[[ -f "$main" ]] || continue
	dir=$(dirname "$main")
	name=$(basename "$dir")
	install_go "$dir" "$name"
done

echo "Done." >&2
