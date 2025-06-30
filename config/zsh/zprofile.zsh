# zsh customizations
[[ ! -f "$HOME/.config/zsh/common-aliases.zsh" ]] || source "$HOME/.config/zsh/common-aliases.zsh"

# homebrew
if [[ "$(uname)" == "Darwin" ]]; then
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -f /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# direnv
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"

# asdf
if [[ -d "$HOME/.asdf" ]]; then
  if [[ -f "$HOME/.asdf/asdf.sh" ]]; then
    source "$HOME/.asdf/asdf.sh"
    fpath=(${ASDF_DIR}/completions $fpath)
  else
    export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
    source <(asdf completion zsh)
  fi

  # asdf plugins
  [[ -d "$HOME/.asdf/plugins/golang" ]] && source ~/.asdf/plugins/golang/set-env.zsh
  [[ -d "$HOME/.asdf/plugins/java" ]] && source ~/.asdf/plugins/java/set-java-home.zsh
fi

# initialize zsh completions
autoload -Uz compinit && compinit

export CLICOLOR=1
export LSCOLORS=exfxcxdxbxegedabagacad
export EDITOR=nvim
export PATH="$HOME/.local/bin:$PATH"

# when using tmux reverse search is not working
# I'm not sure why I need this, but it corrects the issue
bindkey '^R' history-incremental-search-backward

