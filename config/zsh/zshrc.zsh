# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -d "$HOME/powerlevel10k" ]]; then
  source "$HOME/powerlevel10k/powerlevel10k.zsh-theme"
fi

# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit
### End of Zinit's installer chunk

zinit ice depth=1 
zinit load romkatv/powerlevel10k
zinit snippet OMZL::directories.zsh

# load the powerlevel19k config
if [[ -f "$HOME/.p10k.zsh" ]]; then
  source "$HOME/.p10k.zsh"
fi

# add some color to directory listing
export LSCOLORS=exfxcxdxbxegedabagacad

# zsh customizations
[[ ! -f "$HOME/.config/zsh/common-aliases.zsh" ]] || source "$HOME/.config/zsh/common-aliases.zsh"

# brew
eval "$(/opt/homebrew/bin/brew shellenv)"

# direnv
eval "$(direnv hook zsh)"

# asdf
source "$HOME/.asdf/asdf.sh"
fpath=(${ASDF_DIR}/completions $fpath)
autoload -Uz compinit && compinit

# asdf plugins
source ~/.asdf/plugins/golang/set-env.zsh
source ~/.asdf/plugins/java/set-java-home.zsh

export EDITOR=nvim
export PATH="$HOME/.local/bin:$PATH"

# when using tmux reverse search is not working
# I'm not sure why I need this, but it corrects the issue
bindkey '^R' history-incremental-search-backward

