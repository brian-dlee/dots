# zsh customizations
[[ ! -f "$HOME/.config/zsh/common-aliases.zsh" ]] || source "$HOME/.config/zsh/common-aliases.zsh"

# brew
[[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

# direnv
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"

# asdf
if [[ -d "$HOME/.asdf" ]]; then
  source "$HOME/.asdf/asdf.sh"
  fpath=(${ASDF_DIR}/completions $fpath)

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

