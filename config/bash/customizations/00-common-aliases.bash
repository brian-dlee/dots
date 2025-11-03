# Advanced Aliases.
# Use with caution
#

# ls, the common ones I use a lot shortened for rapid fire usage
alias l='ls -lFh --color=auto'   #size,show type,human readable
alias la='ls -lAFh --color=auto' #long list,show almost all,show type,human readable
alias lr='ls -tRFh --color=auto' #sorted by date,recursive,show type,human readable
alias lt='ls -ltFh --color=auto' #long list,sorted by date,show type,human readable
alias ll='ls -al --color=auto'   #long list
alias ldot='ls -ld .* --color=auto'
alias lS='ls -1FSsh --color=auto'
alias lart='ls -1Fcart --color=auto'
alias lrt='ls -1Fcrt --color=auto'

alias bashrc='${EDITOR} ~/.bashrc' # Quick access to the ~/.bashrc file

alias grep='grep --color'
alias sgrep='grep -R -n -H -C 5 --exclude-dir={.git,.svn,CVS} '

alias t='tail -f'

alias dud='du -d 1 -h'
alias duf='du -sh *'
alias fd='find . -type d -name'
alias ff='find . -type f -name'

alias h='history'
alias hgrep='history | grep'
alias help='man'
alias p='ps -f'
alias sortnr='sort -n -r'
alias unexport='unset'

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# SSH host completion for bash
_ssh_completion() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local hosts=""

  # Read known hosts files
  if [[ -f ~/.ssh/known_hosts ]]; then
    hosts="$hosts $(awk '{print $1}' ~/.ssh/known_hosts 2>/dev/null | cut -d, -f1 | grep -v '^\[' | sort -u)"
  fi

  if [[ -f /etc/ssh/ssh_known_hosts ]]; then
    hosts="$hosts $(awk '{print $1}' /etc/ssh/ssh_known_hosts 2>/dev/null | cut -d, -f1 | grep -v '^\[' | sort -u)"
  fi

  COMPREPLY=($(compgen -W "$hosts" -- "$cur"))
}

# Apply SSH completion
complete -F _ssh_completion ssh scp sftp rsync

