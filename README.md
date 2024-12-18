# dots - my dot files

## How to use this

Within the `config` directory of this project, I'll include various 
application configuration files. I won't go into details on how you 
should install this. Copy it, link it, source it... pick your poison. 

Personally, I'll either source it or link it. It depends on the individual config,
but I probably want my config to be live so I can easily commit
changes back to this repository.

## Recommended extras

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

## Fonts

You'll see that a Nerd Font is recommended for configurations like this. I use Powerlevel10k which recommends a very specific font patched just for this zsh theme. It's called "Menlo LGS NF". You can install it by downloading the files from the Powerlevel 10k Github page or by downloading the Homebrew tap `font-meslo-for-powerlevel10k`.

[Powerlevel10k Fonts](https://github.com/romkatv/powerlevel10k?tab=readme-ov-file#meslo-nerd-font-patched-for-powerlevel10k)
[Nerd Fonts](https://www.nerdfonts.com/)

_Note: Nerd Fonts can be downloaded and installed from the website and via Homebrew as they all have individual taps_


## Compile and install the custom tools

_Note: This requires an available installation of Go to compile the tools_

```shell
# By default, these install into $HOME/.local/bin

# install urlencode a shell utility for url-encoding strings
$HOME/dots/tools/urlencode/install.sh

# install prettypath for use by the tmux and zsh prompt
$HOME/dots/tools/prettypath/install.sh
```
