# Hyprland Config Management

This document covers how Hyprland configuration is managed in `.dots`, why it differs from
every other config, and the important nuances to keep in mind.

## Why Hyprland is Different

Most configs in `.dots` are installed as direct symlinks:

```
~/.config/waybar  ->  ~/.dots/config/waybar
~/.config/ghostty ->  ~/.dots/config/ghostty
```

Hyprland cannot use this approach because **omarchy migrations modify `~/.config/hypr`
directly**. If `~/.config/hypr` were a symlink into `.dots`, omarchy upgrades would silently
overwrite tracked files, making `git status` noisy and causing unexpected diffs across machines.

The solution is an intermediate layer: `live/hypr`.

## The `live/hypr` Design

```
~/.dots/config/hypr/   <- source of truth, tracked by .dots git
~/.dots/live/hypr/     <- independent git repo, gitignored by .dots
~/.config/hypr         -> ~/.dots/live/hypr   (symlink)
```

`live/hypr` is a separate git repo that lives inside `.dots` but is excluded from `.dots`
tracking via `.gitignore`. It acts as a buffer:

- **Omarchy migrations** modify `live/hypr` freely — that's their business
- **You** install deliberate changes from `config/hypr/` into `live/hypr/` using
  `install_hyprland_config.sh`, with a safety window before committing
- After an omarchy upgrade, use `git diff` in `live/hypr` to review what changed, then
  decide what to cherry-pick back into `config/hypr/`

## `install_config.sh` and Hyprland

`install_config.sh` intentionally skips Hyprland. The comment in the file reads:

```bash
# Hyprland - managed separately by install_hyprland_config.sh
```

Run `install_config.sh` for everything else (nvim, tmux, waybar, ghostty, etc.), then run
`install_hyprland_config.sh` separately for Hyprland.

## `install_hyprland_config.sh` — Step by Step

### Step 1: Initialize `live/hypr`

If `live/hypr` does not exist, the script creates it as a git repo.

If `~/.config/hypr` already exists at that point (which it will on an existing machine),
the script snapshots it into `live/hypr` using `cp -rL` (following symlinks so that
symlinked shaders are stored as real files for the initial commit). This becomes the
baseline — future `git diff` in `live/hypr` will show only intentional changes from
`.dots`.

If `~/.config/hypr` does not exist, an empty initial commit is created so `git diff` is
still meaningful from day one.

### Step 2: Verify the `~/.config/hypr` symlink

The script ensures `~/.config/hypr` points to `~/.dots/live/hypr`. It handles three cases:

- **Correct symlink** — nothing to do
- **Symlink pointing elsewhere** — updates the target
- **Real directory** — aborts with instructions to back it up manually; the script will
  not silently destroy an unmanaged directory

### Step 3: Dirty check

If `live/hypr` has uncommitted changes the script aborts. This prevents an install from
burying changes that omarchy (or you) made directly to `live/hypr`. The error message
includes the exact commands to review and resolve:

```
cd ~/.dots/live/hypr && git diff
git add . && git commit -m 'your message'
# or
git checkout .
```

### Step 4: Copy `config/hypr/` → `live/hypr/`

```bash
rsync -a --exclude='shaders/' config/hypr/ live/hypr/
```

`rsync` is used instead of `cp` to exclude `shaders/`. Shaders are managed by the Aether
GUI app (see [Shaders](#shaders) below) and must not be overwritten or tracked by `.dots`.

### Step 5: Reload Hyprland

```bash
hyprctl reload
```

The new config takes effect immediately. This is intentional — you can see the changes
live during the confirmation window.

### Step 6: 10-second confirmation window

You have 10 seconds to press `Y` to keep the new config, or it reverts automatically.

**On confirmation (Y):**
- The script prints `git status --short` so you can see what changed
- It suggests the exact commands to review and commit:
  ```
  cd ~/.dots/live/hypr
  git diff
  git add . && git commit -m "install from .dots @ <hash>"
  ```
- It does **not** commit automatically — you decide what message to use and when

**On timeout or any other key:**
- `git checkout .` restores `live/hypr` to its last committed state
- `hyprctl reload` restores the previous config
- The script exits with code 1

## Shaders

`~/.config/hypr/shaders/` contains symlinks to `/usr/share/aether/shaders/`. These are
created by the **Aether GUI app** when it launches (`_installShaders()` in
`AetherApplication.js`). They are not managed by omarchy or `.dots`.

Implications:
- `config/hypr/shaders/` does not exist in this repo
- `live/hypr/.gitignore` excludes `shaders/`
- `install_hyprland_config.sh` excludes `shaders/` from the rsync copy
- Shaders will appear/reappear in `~/.config/hypr/shaders/` after Aether is launched;
  you do not need to do anything to restore them after a fresh install

## Known Limitations

### File Deletions Not Propagated

This system does not handle file deletions. If a file is removed from `config/hypr/`, 
the corresponding file in `live/hypr/` will not be automatically deleted when running 
`install_hyprland_config.sh`.

When you delete a file from `config/hypr/`, you must manually remove it from `live/hypr/` 
on each machine. This compromise is accepted to keep the install script simple and safe.

**Example:**
1. You remove `config/hypr/core/some-feature.conf`
2. Run `install_hyprland_config.sh` on another machine
3. `live/hypr/core/some-feature.conf` still exists and may still be sourced
4. Manual cleanup: `rm ~/.config/hypr/core/some-feature.conf` on each machine

## Machine-Local Files

Files matching the `*.local.*` pattern are machine-specific and gitignored by `.dots`. 
These files are tracked as templates in `config/hypr/` but diverge in `live/hypr/` on 
each machine.

### Templated Local Files

| File | Purpose | Template Version |
|------|---------|------------------|
| `core/machine.local.conf` | Per-machine overrides, sourced last by `hyprland.conf` | `@dots-version: 1` |
| `hypridle/hypridle-features.local.conf` | Enable/disable idle features (suspend, hibernate) per machine | `@dots-version: 1` |

Each template includes a `# @dots-version: N` header. When you make structural changes 
to a template (e.g., add a new feature source), bump the version number. 
`install_hyprland_config.sh` compares template and live versions and warns if the live 
file is stale. Upgrades are manual — review the template diff and update your live file 
accordingly.

### Generated Local Files

| File | Purpose |
|------|---------|
| `core/workspaces.local.conf` | Generated from `workspaces-home.conf` or `workspaces-office.conf` by `switch-workspace-config` |

`workspaces.local.conf` is fully regenerated each time you run `switch-workspace-config`. 
No version tracking is needed — when presets change, just re-run the tool.

## Post-Omarchy-Upgrade Workflow

After running `omarchy update` or any omarchy migration:

1. Check what changed in `live/hypr`:
   ```bash
   cd ~/.dots/live/hypr
   git diff
   git status
   ```

2. For each meaningful change, decide:
   - **Keep in `.dots`**: copy the change into `~/.dots/config/hypr/` and commit it there
   - **Machine-local**: commit it in `live/hypr` with a descriptive message but don't
     propagate to `config/hypr/`
   - **Discard**: `git checkout -- <file>` in `live/hypr`

3. Commit the final state of `live/hypr`:
   ```bash
   git -C ~/.dots/live/hypr add .
   git -C ~/.dots/live/hypr commit -m "post-omarchy-upgrade: <date>"
   ```

## Fresh Machine Setup

On a machine where `.dots` is being installed for the first time:

1. Run `./install.sh` — this handles everything except Hyprland
2. Run `./install_hyprland_config.sh` — this:
   - Creates `live/hypr` (empty initial commit since no `~/.config/hypr` exists yet)
   - Sets the `~/.config/hypr` symlink
   - Copies `config/hypr/` into `live/hypr/`
   - Prompts you to confirm
3. Verify machine-local files were created from templates:
   - `~/.config/hypr/core/machine.local.conf`
   - `~/.config/hypr/hypridle/hypridle-features.local.conf`
   - `~/.config/hypr/core/workspaces.local.conf` (generated by `switch-workspace-config`)
4. Edit machine-local files as needed for this machine (e.g., disable suspend on laptop)
5. Verify monitor config: run `hyprctl monitors` and check `core/monitors.conf` uses the
   correct `desc:` values for this machine's displays

## Directory Reference

```
~/.dots/
├── config/hypr/           # Source of truth — edit configs here, never in live/hypr
│   ├── hyprland.conf
│   ├── hypridle.conf
│   ├── hyprlock.conf
│   ├── hyprsunset.conf
│   ├── envs.local.conf    # gitignored (*.local.*)
│   ├── core/
│   │   ├── machine.local.conf       # templated local file (@dots-version: 1)
│   │   ├── monitors.conf
│   │   ├── bindings.conf
│   │   ├── input.conf
│   │   ├── looknfeel.conf
│   │   ├── autostart.conf
│   │   ├── envs.conf
│   │   ├── windowrules.conf
│   │   ├── workspaces-home.conf     # preset for switch-workspace-config
│   │   ├── workspaces-office.conf   # preset for switch-workspace-config
│   │   └── xdph.conf
│   └── hypridle/
│       ├── hypridle-features.local.conf  # templated local file (@dots-version: 1)
│       └── features/
│           ├── suspend.conf
│           └── hibernate.conf
├── live/                  # gitignored by .dots
│   └── hypr/              # independent git repo
│       ├── .git/
│       ├── .gitignore     # excludes shaders/ and *.local.*
│       ├── core/
│       │   ├── workspaces.local.conf    # generated by switch-workspace-config
│       │   └── [other core files]
│       └── [all above files, plus shaders/ once Aether runs]
└── install_hyprland_config.sh

~/.config/
└── hypr -> ~/.dots/live/hypr    # symlink
```
