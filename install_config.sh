#!/usr/bin/env bash

set -ue

root_path=$(cd "$(dirname "$0")" && pwd)

# Helper to symlink a single file
link_file() {
  local src="$1" dest="$2" label="$3"
  if [[ -e "$dest" ]]; then
    echo "$dest exists. Skipping install." >&2
  else
    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
    echo "Installed $label." >&2
  fi
}

# Helper to symlink a directory
link_dir() {
  local src="$1" dest="$2" label="$3"
  if [[ -e "$dest" ]]; then
    echo "$dest exists. Skipping install." >&2
  else
    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
    echo "Installed $label." >&2
  fi
}

# Neovim
link_dir "$root_path/config/nvim" "$HOME/.config/nvim" "nvim configuration"

# Tmux
link_file "$root_path/config/tmux/tmux.conf" "$HOME/.tmux.conf" "tmux configuration"

# Readline
link_file "$root_path/config/readline/inputrc" "$HOME/.inputrc" "readline configuration"

# Dircolors
link_file "$root_path/config/dircolors/dircolors" "$HOME/.dircolors" "dircolors configuration"

# Terminal emulators
link_dir "$root_path/config/alacritty" "$HOME/.config/alacritty" "alacritty configuration"
link_dir "$root_path/config/ghostty" "$HOME/.config/ghostty" "ghostty configuration"
link_dir "$root_path/config/kitty" "$HOME/.config/kitty" "kitty configuration"

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

# Install shell configuration based on current shell
if [[ $# -gt 0 ]]; then
  current_shell=$1
else
  current_shell=$(basename "$SHELL")
fi

case "$current_shell" in
zsh)
  echo "Installing zsh configuration..." >&2

  zshrc_source="source \"$root_path/config/zsh/zshrc.zsh\""
  if [[ -f ~/.zshrc ]]; then
    if ! grep -Fq "$zshrc_source" ~/.zshrc; then
      echo "$zshrc_source" >>~/.zshrc
      echo "Added zshrc source to existing ~/.zshrc" >&2
    else
      echo "zshrc source already exists in ~/.zshrc" >&2
    fi
  else
    echo "$zshrc_source" >~/.zshrc
    echo "Created ~/.zshrc with zshrc source" >&2
  fi

  zprofile_source="source \"$root_path/config/zsh/zprofile.zsh\""
  if [[ -f ~/.zprofile ]]; then
    if ! grep -Fq "$zprofile_source" ~/.zprofile; then
      echo "$zprofile_source" >>~/.zprofile
      echo "Added zprofile source to existing ~/.zprofile" >&2
    else
      echo "zprofile source already exists in ~/.zprofile" >&2
    fi
  else
    echo "$zprofile_source" >~/.zprofile
    echo "Created ~/.zprofile with zprofile source" >&2
  fi

  mkdir -p ~/.config
  if [[ -e ~/.config/zsh ]]; then
    echo "$HOME/.config/zsh exists. Skipping install." >&2
  else
    ln -s "$root_path/config/zsh" "$HOME/.config/zsh"
    echo "Installed zsh config directory." >&2
  fi
  ;;

bash)
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

  mkdir -p ~/.config
  if [[ -e ~/.config/bash ]]; then
    echo "$HOME/.config/bash exists. Skipping install." >&2
  else
    ln -s "$root_path/config/bash" "$HOME/.config/bash"
    echo "Installed bash config directory." >&2
  fi
  ;;

*)
  echo "Unsupported shell: $current_shell. Skipping shell configuration." >&2
  ;;
esac

echo Done >&2
