#!/usr/bin/env bash

set -ue

root_path=$(cd "$(dirname "$0")" && pwd)

echo "Installing prettypath" >&2
"$root_path/tools/prettypath/install.sh"

echo "Installing urlencode" >&2
"$root_path/tools/urlencode/install.sh"

# Install workspace tools to ~/.local/bin
echo "Installing workspace tools..." >&2
mkdir -p "$HOME/.local/bin"

for tool in switch-workspace-config force-workspace-monitors; do
    src="$root_path/tools/$tool"
    dest="$HOME/.local/bin/$tool"
    
    if [[ -L "$dest" ]] && [[ "$(readlink -f "$dest")" == "$src" ]]; then
        echo "$tool is up to date."
        continue
    fi
    
    rm -f "$dest"
    ln -s "$src" "$dest"
    echo "Installed $tool -> ~/.local/bin/$tool"
done

echo "Done." >&2
