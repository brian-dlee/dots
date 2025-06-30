# bash customizations
[[ ! -f "$HOME/.config/bash/customizations/common-aliases.bash" ]] || source "$HOME/.config/bash/customizations/common-aliases.bash"

# homebrew
if [[ "$(uname)" == "Darwin" ]]; then
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -f /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# direnv
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook bash)"

# asdf
if [[ -d "$HOME/.asdf" ]]; then
  source "$HOME/.asdf/asdf.sh"
  source "$HOME/.asdf/completions/asdf.bash"

  # asdf plugins
  [[ -f "$HOME/.asdf/plugins/golang/set-env.bash" ]] && source "$HOME/.asdf/plugins/golang/set-env.bash"
  [[ -f "$HOME/.asdf/plugins/java/set-java-home.bash" ]] && source "$HOME/.asdf/plugins/java/set-java-home.bash"
fi

export CLICOLOR=1
export LSCOLORS=exfxcxdxbxegedabagacad
export EDITOR=nvim
export PATH="$HOME/.local/bin:$PATH"

# when using tmux reverse search is not working
# I'm not sure why I need this, but it corrects the issue
bind '"\C-r": reverse-search-history'
