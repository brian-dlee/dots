#!/usr/bin/env bash

set -ue

root_path=$(cd "$(dirname "$0")" && pwd)

if [[ -e ~/.config/nvim ]]; then
  echo "$HOME/.config/nvim exists. Skipping install." >&2
else
  mkdir -p ~/.config
  ln -s "$root_path/config/nvim" "$HOME/.config/nvim"
  echo "Installed nvim configuration." >&2
fi

if [[ -e ~/.tmux.conf ]]; then
  echo "$HOME/.tmux.conf exists. Skipping install." >&2
else
  ln -s "$root_path/config/tmux/tmux.conf" "$HOME/.tmux.conf"
  echo "Installed tmux configuration." >&2
fi

if [[ -e ~/.inputrc ]]; then
  echo "$HOME/.inputrc exists. Skipping install." >&2
else
  ln -s "$root_path/config/readline/inputrc" "$HOME/.inputrc"
  echo "Installed readline configuration." >&2
fi

# Install shell configuration based on current shell
current_shell=$(basename "$SHELL")

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
