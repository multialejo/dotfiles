# dotfiles

Personal dotfiles: configs, essential package list, and scripts to recreate my
work environment on any Linux distro.

## Structure

```
config/          mirror of ~/.config apps + shell dotfiles
  nvim/          LazyVim setup
  kitty/         kitty.conf
  tmux/          tmux.conf
  .bash-omarchy  Omarchy bash extras (envs, aliases, init) ported to work
                 on any distro; sourced from .bashrc
  .inputrc       readline config (from Omarchy, self-contained)
  .bashrc        standalone (user aliases, no Omarchy dependency)
  .bash_profile
packages.list    essential packages, one per line, distro-agnostic
scripts/         personal scripts (pomodoro_timer.sh, rcsync, ueb-update)
apply.sh         symlink config/ into the home directory
install.sh       report packages from packages.list that are missing
```

## Bash extras (.bash-omarchy)

`.bashrc` includes `~/.bash-omarchy` with a single commented line:

```sh
[ -f ~/.bash-omarchy ] && source ~/.bash-omarchy
```

- Comment that line out on distros where Omarchy is installed and already
  provides these extras (avoids duplicate PATH/init).
- The port guards every alias with `command -v`: tools that aren't installed
  on the distro simply don't get aliases, no startup errors.
- Omarchy's `fns/*` functions and custom completions are NOT ported (they
  depend on `$OMARCHY_PATH`) - see Next steps.

## Setup on a new machine

```sh
git clone git@github.com:multialejo/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 1. Symlink configs (idempotent, add --dry-run to preview)
./apply.sh

# 2. See which packages are missing (never installs anything)
./install.sh
# Paste the printed install command, or hand the missing list to an AI agent.
```

## Workflow

- Edit configs in place: symlinks mean `~/.config/<app>` edits are already
  versioned. Commit them from the repo.
- `install.sh` output is agent-friendly: a bare list of missing packages plus
  the exact install command for the detected manager (pacman/dnf/apt).

## Next steps (backlog)

- Per-distro package translation (some names differ: `python-pip` vs `python3-pip`)
- Flatpak fallback for desktop apps not in repos (typora, localsend)
- Optional Omarchy layer on Arch (full desktop environment); on other distros
  only `config/` + essential packages apply
- `experiments/` (gitignored): clone popular rices (HyDE, END-4, archdotfiles)
  to study and cherry-pick ideas into `config/`
- Port Omarchy `fns/*` functions and custom completions that don't depend on
  omarchy bins into `.bash-omarchy`
- `bin/` one-command-per-action CLI, Omarchy style
