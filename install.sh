#!/usr/bin/env bash
#
# Complete installation script for dotfiles repository
# Installs both configuration files and custom tools

set -e

root_path=$(cd "$(dirname "$0")" && pwd)

echo "Installing dotfiles from $root_path" >&2

# Function to check if command exists
command_exists() {
	command -v "$1" >/dev/null 2>&1
}

# Function to compare version numbers
version_gte() {
	printf '%s\n%s\n' "$2" "$1" | sort -V -C
}

# Function to install asdf plugins
install_asdf_plugins() {
	local plugins=("golang" "nodejs" "python" "rust")
	local existing_plugins

	echo "Installing asdf plugins..." >&2

	# Get list of existing plugins
	existing_plugins=$(asdf plugin list 2>/dev/null || echo "")

	for plugin in "${plugins[@]}"; do
		if echo "$existing_plugins" | grep -q "^$plugin$"; then
			echo "Plugin $plugin already installed" >&2
		else
			echo "Installing asdf plugin: $plugin" >&2
			if asdf plugin add "$plugin" 2>/dev/null; then
				echo "Successfully added $plugin plugin" >&2
			else
				echo "Warning: Failed to add $plugin plugin" >&2
			fi
		fi
	done

	echo "" >&2
	echo "asdf plugins installed. Use 'asdf install <plugin> <version or 'latest'>' to install versions." >&2
}

# Check for required dependencies
echo "Checking dependencies..." >&2

if ! command_exists "go"; then
	echo "Warning: Go is not installed. Custom tools will not be compiled." >&2
	echo "Install Go from https://golang.org/dl/ to compile prettypath and urlencode tools." >&2
	SKIP_TOOLS=true
else
	echo "Go found: $(go version)" >&2
	SKIP_TOOLS=false
fi

if ! command_exists "tmux"; then
	echo "Warning: tmux is not installed. Configuration will be linked but tmux is required to use it." >&2
	echo "Install tmux via your package manager (e.g., 'yay tmux' or 'sudo pacman -S tmux')." >&2
fi

# Install configuration files
echo "" >&2
echo "Installing configuration files..." >&2
"$root_path/install_config.sh"

# Check for asdf and install plugins if version >= 0.16.0
if command_exists "asdf"; then
	asdf_version=$(asdf version 2>/dev/null | head -n1 | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' | sed 's/v//')
	if [[ -n "$asdf_version" ]] && version_gte "$asdf_version" "0.16.0"; then
		echo "" >&2
		echo "asdf $asdf_version found (>= 0.16.0)" >&2
		install_asdf_plugins
	else
		echo "" >&2
		echo "asdf found but version $asdf_version is < 0.16.0, skipping plugin installation" >&2
	fi
else
	echo "" >&2
	echo "asdf not found, skipping plugin installation" >&2
fi

# Install custom tools
echo "" >&2
echo "Installing custom tools..." >&2

if [[ "$SKIP_TOOLS" != "true" ]]; then
	"$root_path/install_tools.sh"
	echo "" >&2
	echo "Custom tools installed to ~/.local/bin" >&2
	echo "Make sure ~/.local/bin is in your PATH" >&2
else
	echo "Skipping Go tools (Go not found), installing workspace tools only..." >&2
	# Install workspace tools (no Go required)
	mkdir -p "$HOME/.local/bin"
	for tool in switch-workspace-config force-workspace-monitors; do
		src="$root_path/tools/$tool"
		dest="$HOME/.local/bin/$tool"
		if [[ -L "$dest" ]] && [[ "$(readlink -f "$dest")" == "$src" ]]; then
			echo "$tool is up to date." >&2
		else
			rm -f "$dest"
			ln -s "$src" "$dest"
			echo "Installed $tool -> ~/.local/bin/$tool" >&2
		fi
	done
fi

echo "" >&2
echo "Installation complete!" >&2
echo "" >&2
echo "Next steps:" >&2
echo "1. Restart your shell or source your shell config:" >&2
echo "   source ~/.bashrc" >&2
echo "2. Install recommended tools (see README.md):" >&2
echo "   - starship (prompt)" >&2
echo "   - asdf (version manager)" >&2
echo "   - direnv (directory environment)" >&2
echo "   - neovim (editor)" >&2
echo "   - lazygit (git interface)" >&2
echo "   - tmux (terminal multiplexer)" >&2
echo "   - tpm (tmux plugin manager):" >&2
echo "     git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm" >&2
echo "3. Install Hyprland config with safe rollback:" >&2
echo "   ./install_hyprland_config.sh" >&2
echo "" >&2
