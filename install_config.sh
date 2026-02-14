#!/usr/bin/env bash

set -ue

root_path=$(cd "$(dirname "$0")" && pwd)

# Prompt for replacing an existing config
# Usage: prompt_replace src dest label remove_cmd
# Returns 0 if replaced, 1 if skipped
prompt_replace() {
  local src="$1" dest="$2" label="$3" remove_cmd="$4"
  while true; do
    read -r -p "Replace with repo version? [y]es (backup) / [Y]es (no backup) / [n]o: " choice </dev/tty
    case "$choice" in
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
        echo "Please enter y, Y, or n." >&2
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
  diff --color -u --label "existing: $dest" --label "repo: $src" "$dest" "$src" >&2 || true
  echo "" >&2
  prompt_replace "$src" "$dest" "$label" "rm \"$dest\""
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
  diff --color -rq "$dest" "$src" >&2 || true
  echo "" >&2
  prompt_replace "$src" "$dest" "$label" "rm -r \"$dest\""
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

# Hyprland (individual file symlinks — omarchy manages the directory)
for conf in bindings input monitors envs looknfeel autostart hypridle hyprlock hyprsunset xdph; do
  link_file "$root_path/config/hypr/$conf.conf" "$HOME/.config/hypr/$conf.conf" "hypr $conf configuration"
done

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
