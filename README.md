# dots - my dot files

## Quick Install

```bash
git clone git@github.com:brian-dlee/dots.git ~/.dots
cd ~/.dots
./install.sh
```

This installs all configuration files and custom tools. After it completes, install the
Hyprland config separately (it requires interactive confirmation — see details below):

```bash
./install_hyprland_config.sh
```

Restart your shell or source your config when done.

## What's Included

### Configuration Files (`config/`)

- **bash** - Bash shell configuration with aliases
- **dircolors** - Custom color scheme for `ls` command
- **git** - Shared git config (aliases, diff, pull/push, rerere) and global gitignore
- **ghostty** - Ghostty terminal configuration
- **hypr** - Hyprland window manager configuration — source of truth, installed via `install_hyprland_config.sh` (see [docs/hyprland-config.md](docs/hyprland-config.md))
- **nvim** - Neovim editor configuration (LazyVim-based)
- **omarchy** - Omarchy desktop customizations (hooks, extensions, branding)
- **readline** - Input configuration for bash/readline
- **starship** - Starship cross-shell prompt configuration
- **tmux** - Terminal multiplexer configuration
- **walker** - Application launcher configuration
- **waybar** - Status bar configuration

### Custom Tools (`tools/`)

- **prettypath** - Path formatter for tmux and shell prompts
- **urlencode** - URL encoding utility for shell
- **switch-workspace-config** - Switch between workspace layout configs (home/office)
- **force-workspace-monitors** - Force workspace-to-monitor assignments

## Manual Installation

### Configuration Files Only
```bash
./install_config.sh
```

### Hyprland Config (interactive, with rollback)
```bash
./install_hyprland_config.sh
```

See [docs/hyprland-config.md](docs/hyprland-config.md) for details on how this works and
important nuances around machine-local files, shaders, and omarchy upgrades.

### Custom Tools Only
```bash
# Requires Go to be installed
./tools/prettypath/install.sh
./tools/urlencode/install.sh
```

## Configuration Details

### Shell Configuration
- Bash configuration includes:
  - Color support with dircolors
  - Common aliases for ls, grep, etc.
  - History settings and completion
  - Starship prompt
  - Clipboard helpers (cross-platform)
  - eza integration (modern ls replacement)

### Desktop Environment (Hyprland/Omarchy)
- `config/hypr/` is the source of truth tracked by this repo
- `~/.config/hypr` is a symlink to `~/.dots/live/hypr`, an independent git repo (gitignored by `.dots`)
- `install_hyprland_config.sh` copies `config/hypr/` into `live/hypr/` with a 10-second
  rollback window before you confirm the change
- This design lets omarchy migrations modify `live/hypr` freely without dirtying `.dots`;
  after an omarchy upgrade you can `git diff` in `live/hypr` to review what changed, then
  cherry-pick into `config/hypr/`
- Shaders in `~/.config/hypr/shaders/` are managed by the Aether GUI app, not this repo;
  they are gitignored in `live/hypr`
- System-agnostic monitor config using `desc:` identifiers
- Run `hyprctl monitors` to find monitor descriptions for new displays
- Waybar, Walker, and terminal configs are symlinked directly (no `live/` indirection)

### Color Support
- Linux-compatible LS_COLORS via dircolors
- Color-enabled aliases for ls commands
- Supports custom color schemes via ~/.dircolors

### Editor Integration
- Neovim configuration based on LazyVim
- Tmux integration with editor
- Shell EDITOR variable set to nvim

## Recommended extras

### starship - https://starship.rs/

Fast, cross-shell prompt with minimal configuration. Install via your package manager or `curl -sS https://starship.rs/install.sh | sh`.

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

### tmux - https://github.com/tmux/tmux

Terminal multiplexer used for managing multiple terminal sessions. The config uses tpm (tmux plugin manager) - see installation below.

### tpm - https://github.com/tmux-plugins/tpm

Tmux plugin manager. After installing tmux, clone the repo and source your tmux config:

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
# Restart tmux or press prefix + I to install plugins
```

## Fonts

A Nerd Font is recommended for terminal configurations. The configs use CaskaydiaMono Nerd Font by default, which provides all the glyphs needed for starship, neovim, and the desktop environment.

[Nerd Fonts](https://www.nerdfonts.com/)

_Note: Nerd Fonts can be downloaded and installed from the website and via Homebrew as they all have individual taps_

## Requirements

- **Git** - For cloning the repository
- **Go** (optional) - Required only for compiling custom tools
- **Bash** - Shell configuration
- **Starship** - Cross-shell prompt
- **Nerd Font** - For proper display of special characters (see Fonts section)
- **tmux** - Terminal multiplexer
- **tpm** - [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm)

## Installation Notes

- Most configuration files are symlinked directly from `~/.dots/config/` to `~/.config/`
- Hyprland config is different: `~/.config/hypr` → `~/.dots/live/hypr` (an independent git repo);
  `config/hypr/` is copied into `live/hypr/` by `install_hyprland_config.sh`, not symlinked
- Custom tools install to `~/.local/bin` by default
- Shell configurations are sourced from existing config files when possible
- `install_config.sh` shows diffs and prompts before replacing existing configs
- Files matching `*.local.*` are gitignored — use this pattern for machine-specific overrides
