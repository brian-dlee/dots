#!/usr/bin/env bash

set -ue

root_path=$(cd "$(dirname "$0")" && pwd)

# Prompt for replacing an existing config
# Usage: prompt_replace src dest label remove_cmd diff_cmd
# Returns 0 if replaced, 1 if skipped
prompt_replace() {
  local src="$1" dest="$2" label="$3" remove_cmd="$4" diff_cmd="$5"
  while true; do
    read -r -p "Replace with repo version? [d]iff / [y]es (backup) / [Y]es (no backup) / [n]o: " choice </dev/tty
    case "$choice" in
      d)
        echo "" >&2
        eval "$diff_cmd" >&2 || true
        echo "" >&2
        ;;
      y)
        mv "$dest" "${dest}.bak"
        ln -s "$src" "$dest"
        echo "Applied $label. Backup: ${dest}.bak" >&2
        return 0
        ;;
      Y)
        eval "$remove_cmd"
        ln -s "$src" "$dest"
        echo "Applied $label." >&2
        return 0
        ;;
      n)
        echo "Skipped $label." >&2
        return 1
        ;;
      *)
        echo "Please enter d, y, Y, or n." >&2
        ;;
    esac
  done
}

# Symlink a single file with interactive diff on conflict
link_file() {
  local src="$1" dest="$2" label="$3"
  if [[ ! -e "$dest" && ! -L "$dest" ]]; then
    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
    echo "Installed $label." >&2
    return
  fi
  if [[ -L "$dest" ]] && [[ "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
    echo "$label is up to date." >&2
    return
  fi
  echo "" >&2
  echo "=== $label ===" >&2
  prompt_replace "$src" "$dest" "$label" "rm \"$dest\"" "diff --color -u --label 'existing: $dest' --label 'repo: $src' '$dest' '$src'"
}

# Symlink a directory with interactive diff on conflict
link_dir() {
  local src="$1" dest="$2" label="$3"
  if [[ ! -e "$dest" && ! -L "$dest" ]]; then
    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
    echo "Installed $label." >&2
    return
  fi
  if [[ -L "$dest" ]] && [[ "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
    echo "$label is up to date." >&2
    return
  fi
  echo "" >&2
  echo "=== $label ===" >&2
  prompt_replace "$src" "$dest" "$label" "rm -r \"$dest\"" "diff --color -ru '$dest' '$src'"
}

# Neovim
link_dir "$root_path/config/nvim" "$HOME/.config/nvim" "nvim configuration"

# Tmux
link_file "$root_path/config/tmux/tmux.conf" "$HOME/.tmux.conf" "tmux configuration"

# Readline
link_file "$root_path/config/readline/inputrc" "$HOME/.inputrc" "readline configuration"

# Dircolors
link_file "$root_path/config/dircolors/dircolors" "$HOME/.dircolors" "dircolors configuration"

# Git configuration (include-based so local identity config coexists)
git_include="[include]\n\tpath = $root_path/config/git/config"
mkdir -p "$HOME/.config/git"
if [[ -f "$HOME/.config/git/config" ]]; then
  if ! grep -Fq "$root_path/config/git/config" "$HOME/.config/git/config"; then
    printf '%b\n' "$git_include" >> "$HOME/.config/git/config"
    echo "Added git config include to existing ~/.config/git/config" >&2
  else
    echo "git config include already exists." >&2
  fi
else
  printf '%b\n' "$git_include" > "$HOME/.config/git/config"
  echo "Created ~/.config/git/config with include." >&2
fi
link_file "$root_path/config/git/ignore" "$HOME/.config/git/ignore" "git global ignore"

# Ghostty terminal
link_dir "$root_path/config/ghostty" "$HOME/.config/ghostty" "ghostty configuration"

# Hyprland
link_dir "$root_path/config/hypr" "$HOME/.config/hypr" "hypr configuration"

# Ensure local.conf exists for hyprland
local_conf="$HOME/.config/hypr/local.conf"
if [[ ! -f "$local_conf" ]]; then
  echo "# Local machine configuration" > "$local_conf"
  echo "# This file is imported by hyprland.conf" >> "$local_conf"
  echo "" >> "$local_conf"
  echo "# === Environment Variables ===" >> "$local_conf"
  echo "# example_var = value" >> "$local_conf"
  echo "Created $local_conf." >&2
fi

# Ensure hypridle-features.conf exists with commented-out feature imports
hypridle_dir="$HOME/.config/hypr/hypridle"
hypridle_features="$hypridle_dir/hypridle-features.conf"
mkdir -p "$hypridle_dir/features"
if [[ ! -f "$hypridle_features" ]]; then
  echo "# Hypridle feature toggles" > "$hypridle_features"
  echo "# Uncomment to enable:" >> "$hypridle_features"
  for feature in "$root_path/config/hypr/hypridle/features"/*.conf; do
    if [[ -f "$feature" ]]; then
      feature_name=$(basename "$feature")
      echo "# source = ~/.config/hypr/hypridle/features/$feature_name" >> "$hypridle_features"
    fi
  done
  echo "Created $hypridle_features with feature templates." >&2
else
  for feature in "$root_path/config/hypr/hypridle/features"/*.conf; do
    if [[ -f "$feature" ]]; then
      feature_name=$(basename "$feature")
      if ! grep -qF "$feature_name" "$hypridle_features"; then
        echo "# source = ~/.config/hypr/hypridle/features/$feature_name" >> "$hypridle_features"
        echo "Added feature template: $feature_name" >&2
      fi
    fi
  done
fi

# Waybar
link_dir "$root_path/config/waybar" "$HOME/.config/waybar" "waybar configuration"

# Walker
link_dir "$root_path/config/walker" "$HOME/.config/walker" "walker configuration"

# Omarchy customizations (subdirectory symlinks — omarchy manages the parent)
for subdir in hooks extensions branding; do
  link_dir "$root_path/config/omarchy/$subdir" "$HOME/.config/omarchy/$subdir" "omarchy $subdir"
done

# Starship prompt
link_file "$root_path/config/starship/starship.toml" "$HOME/.config/starship.toml" "starship configuration"

# Bash shell configuration
echo "Installing bash configuration..." >&2

bashrc_source="source \"$root_path/config/bash/bashrc.bash\""
if [[ -f ~/.bashrc ]]; then
  if ! grep -Fq "$bashrc_source" ~/.bashrc; then
    echo "$bashrc_source" >>~/.bashrc
    echo "Added bashrc source to existing ~/.bashrc" >&2
  else
    echo "bashrc source already exists in ~/.bashrc" >&2
  fi
else
  echo "$bashrc_source" >~/.bashrc
  echo "Created ~/.bashrc with bashrc source" >&2
fi

bash_profile_source="source \"$root_path/config/bash/bash_profile.bash\""
if [[ -f ~/.bash_profile ]]; then
  if ! grep -Fq "$bash_profile_source" ~/.bash_profile; then
    echo "$bash_profile_source" >>~/.bash_profile
    echo "Added bash_profile source to existing ~/.bash_profile" >&2
  else
    echo "bash_profile source already exists in ~/.bash_profile" >&2
  fi
else
  echo "$bash_profile_source" >~/.bash_profile
  echo "Created ~/.bash_profile with bash_profile source" >&2
fi

link_dir "$root_path/config/bash" "$HOME/.config/bash" "bash config directory"

echo Done >&2
