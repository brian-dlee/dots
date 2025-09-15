# dots - my dot files

## Quick Install

```bash
git clone <repository-url> ~/.dots
cd ~/.dots
./install.sh
```

This will install all configuration files and custom tools. Restart your shell or source your config when done.

## What's Included

### Configuration Files (`config/`)

- **alacritty** - Terminal emulator configuration
- **bash** - Bash shell configuration with aliases
- **dircolors** - Custom color scheme for `ls` command  
- **ghostty** - Ghostty terminal configuration
- **nvim** - Neovim editor configuration (LazyVim-based)
- **p10k** - Powerlevel10k theme configuration
- **readline** - Input configuration for bash/readline
- **tmux** - Terminal multiplexer configuration
- **zsh** - Zsh shell configuration with aliases

### Custom Tools (`tools/`)

- **prettypath** - Path formatter for tmux and shell prompts
- **urlencode** - URL encoding utility for shell

## Manual Installation

If you prefer manual installation or want to install specific components:

### Configuration Files Only
```bash
./install_all_config.sh
```

### Custom Tools Only
```bash
# Requires Go to be installed
./tools/prettypath/install.sh
./tools/urlencode/install.sh
```

## Configuration Details

### Shell Configuration
- Both bash and zsh configurations include:
  - Color support with dircolors
  - Common aliases for ls, grep, etc.
  - History settings and completion
  - Custom prompt configuration

### Color Support
- Linux-compatible LS_COLORS via dircolors
- Color-enabled aliases for ls commands
- Supports custom color schemes via ~/.dircolors

### Editor Integration
- Neovim configuration based on LazyVim
- Tmux integration with editor
- Shell EDITOR variable set to nvim

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


## Requirements

- **Git** - For cloning the repository
- **Go** (optional) - Required only for compiling custom tools
- **Bash or Zsh** - Supported shells
- **Nerd Font** - For proper display of special characters (see Fonts section)

## Installation Notes

- Configuration files are symlinked, not copied, so changes sync with the repository
- Custom tools install to `~/.local/bin` by default
- Shell configurations are sourced from existing config files when possible
- The installer checks for existing files and won't overwrite them
