# Advanced Aliases

alias l='ls -lFh'   # size,show type,human readable
alias la='ls -lAFh' # long list,show almost all,show type,human readable
alias lr='ls -tRFh' # sorted by date,recursive,show type,human readable
alias lt='ls -ltFh' # long list,sorted by date,show type,human readable
alias ll='ls -l'    # long list

alias zshrc='${=EDITOR} ~/.zshrc' # Quick access to the ~/.zshrc file

alias grep='grep --color'
alias sgrep='grep -R -n -H -C 5 --exclude-dir={.git,.svn,CVS} '

alias t='tail -f'

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Make zsh know about hosts already accessed by SSH
zstyle -e ':completion:*:(ssh|scp|sftp|rsh|rsync):hosts' hosts 'reply=(${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) /dev/null)"}%%[# ]*}//,/ })'
