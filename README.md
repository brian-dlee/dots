# dots - my dot files

## Recommended extras that I do not provide

### asdf - https://asdf-vm.com/

`asdf` is a version manager for all tools. Instead of managing pyenv and nvm and everything else on your
system, you can just use `asdf` to configure local versions of virtually every tool for project specific
versioning or global versioning.

### direnv - https://direnv.net/

`direnv` is like `dotenv` files but with the full power and flexibility of the shell. You can use
them to automatically perform all kinds of tasks once you `cd` into a directory. The most common
task is to set environment variables. I highly recommend this tool over the traditional `.env`
file as this can read those as well! You lose nothing, but gain quite a lot once you explore it.

_Note: This can be installed with `asdf` if you wish_

### neovim - https://neovim.io/

If you plan on using my neovim config you'll probably need this! But you probably already have it then
don't you :)

_Note: If you won't be using neovim you better remove or override the `export EDITOR=nvim` from the shell config_

### lazygit - https://github.com/jesseduffield/lazygit

No single tool has made git tasks faster than `lazygit`. This thing is amazing. With 5 keystrokes, I can 
commit a branch and open a PR against a custom target branch. That's not including my commit message
or typing of my branch name of course. Let's not get carried away.

## Install Guide

1. Clone this repository (duh)

Start by cloning this repository to your home directory: `~/dots`

2. Configure `zsh`

Add `source $HOME/dots/zsh/zshrc.zsh` to your `$HOME/.zshrc`

3. Create your `.local` and `.config` directories if they don't exist

```shell
mkdir -p "$HOME/.local/bin" "$HOME/.config"
```

4. Link the neovim config

```shell
$ ln -s "../dots/config/nvim" "$HOME/.config/nvim"
```

5. Source the tmux config

Add the following line your tmux config: `$HOME/.tmux.conf`

```tmux
source-file ~/dots/config/tmux/tmux.conf
```

## Compile and install the custom tools

_Note: This requires an available installation of Go to compile the tools_

```shell
# By default, these install into $HOME/.local/bin

# install urlencode a shell utility for url-encoding strings
$HOME/dots/tools/urlencode/install.sh

# install prettypath for use by the tmux and zsh prompt
$HOME/dots/tools/prettypath/install.sh
```
