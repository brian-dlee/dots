# zsh customizations
[[ ! -f "$HOME/.config/zsh/common-aliases.zsh" ]] || source "$HOME/.config/zsh/common-aliases.zsh"

# brew
[[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

# direnv
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"

# asdf
if [[ -d "$HOME/.asdf" ]]; then
  fpath=(${ASDF_DATA_DIR:-$HOME/.asdf}/completions $fpath)

  # asdf plugins
  # this next line is recommended by the author, but it prevents customization of the GOBIN variable
  # edit: I modified the file myself (see the bottom of this file)
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

# I changed the content of golang/set-env.zsh to this
# asdf_update_golang_env() {
#   local go_bin_path
#   go_bin_path="$(asdf which go 2>/dev/null)"
#   if [[ -n "${go_bin_path}" ]]; then
#     export GOROOT
#     GOROOT="$(dirname "$(dirname "${go_bin_path:A}")")"
#
#     export GOPATH
#     GOPATH="$(dirname "${GOROOT:A}")/packages"
#   fi
# }
#
# autoload -U add-zsh-hook
# add-zsh-hook precmd asdf_update_golang_env

