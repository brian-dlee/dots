# Install Guide

# Recommended extras

 - asdf
 - direnv
 - neovim
 - lazygit

1. Clone this repository

Start by cloning this repository to your home directory: `~/dots`

1. Configure `zsh`

Add `source $HOME/dots/zsh/zshrc.zsh` to your `$HOME/.zshrc`

1. Create your `.local` and `.config` directories if they don't exist

```shell
mkdir -p "$HOME/.local/bin" "$HOME/.config"
```

1. Link the neovim config

```shell
$ ln -s "../dots/config/nvim" "$HOME/.config/nvim"
```

1. Source the tmux config

Add the following line your tmux config: `$HOME/.tmux.conf`

```tmux
source-file ~/dots/config/tmux/tmux.conf
```

# Compile and install tools

_Note: This requires an available installation of Go to compile the tools_

```shell
# install urlencode a shell utility for url-encoding strings
$HOME/dots/tools/urlencode/install.sh

# install prettypath for use by the tmux and zsh prompt
$HOME/dots/tools/prettypath/install.sh
```
