# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# History configuration
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s histappend

# Check window size after each command
shopt -s checkwinsize

# Enable color support
if [ -x /usr/bin/dircolors ]; then
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# Enable programmable completion features
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

export EDITOR=nvim
export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
export PATH="$HOME/.local/bin:$PATH"
export CLICOLOR=1
export LSCOLORS=exfxcxdxbxegedabagacad

# asdf
if [[ -d "$HOME/.asdf" ]]; then
  if [[ -f "$HOME/.asdf/asdf.sh" ]]; then
    source "$HOME/.asdf/asdf.sh"
    source "$HOME/.asdf/completions/asdf.bash"
  else
    export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
    source <(asdf completion bash)
  fi

  # asdf plugins
  [[ -f "$HOME/.asdf/plugins/golang/set-env.bash" ]] && source "$HOME/.asdf/plugins/golang/set-env.bash"
  [[ -f "$HOME/.asdf/plugins/java/set-java-home.bash" ]] && source "$HOME/.asdf/plugins/java/set-java-home.bash"
fi

# bash customizations
for customization in "$HOME"/.config/bash/customizations/*.bash; do
  source "$customization"
done

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

# when using tmux reverse search is not working
# I'm not sure why I need this, but it corrects the issue
bind '"\C-r": reverse-search-history'
