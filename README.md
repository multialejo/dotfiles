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
setup-ai.sh      bootstrap the Gentle-AI ecosystem (OpenCode + Engram + SDD)
```

## Bash extras (.bash-omarchy)

`.bashrc` includes `~/.bash-omarchy` with a single commented line:

```sh
[ -f ~/.bash-omarchy ] && source ~/.bash-omarchy
```

- Comment that line out on distros where Omarchy is installed and already
  provides these extras (avoids duplicate PATH/init).
- `apply.sh` is Omarchy-aware: when Omarchy is present it always skips the
  entries Omarchy manages (`.bashrc`, `kitty`, `tmux`) - Omarchy re-copies
  its upstream versions on every update, and symlinking them would let
  Omarchy's `cp` write through the link and clobber the repo. `--force`
  does not override this.
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

# 3. AI agent ecosystem (OpenCode + Gentle-AI + Engram + SDD + skills)
./setup-ai.sh
# Add --dry-run to preview, --yes to skip confirmations,
# --persona neutral for a persona without regionalisms (default: gentleman).
```

## AI agent ecosystem (setup-ai.sh)

`setup-ai.sh` bootstraps the Gentle-AI stack on any supported Linux distro
(Ubuntu/Debian, Arch, Fedora/RHEL). Idempotent: re-running reconciles the
ecosystem with the installed gentle-ai version.

What it does:

1. Checks prerequisites (`git`, `curl`, Node.js >= 18, `npm`) and prints the
   exact install command for the detected package manager if anything is missing.
2. Installs `opencode` globally via npm if missing (asks for confirmation).
3. Installs `gentle-ai` with the official installer if missing.
4. Runs `gentle-ai install --agent opencode --preset full-gentleman
   --persona gentleman --scope global` (Engram + SDD + skills + Context7 + GGA
   + permissions + theme).
5. Ensures the `opencode-go` provider block exists in `opencode.json` (the SDD
   model profiles reference its models).
6. Creates the four SDD model profiles: `free-explore` (qwen3.7-plus base),
   `free-design` (deepseek-v4-pro on `sdd-design`), `free-impl`
   (kimi-k2.7-code on `sdd-apply`), `free-verify` (qwen3.7-max on `sdd-verify`).
7. Runs `gentle-ai sync` + `gentle-ai doctor`.

Notes:

- The OpenCode config (`~/.config/opencode/`) is **managed by gentle-ai**, not
  symlinked from this repo - same rule as the Omarchy-managed entries in
  `apply.sh`. After a `gentle-ai upgrade`, run `gentle-ai sync` first.
- Community plugins (`opencode-subagent-statusline`, `sdd-engram-plugin`) are
  not installed by the script for determinism; add them with the gentle-ai TUI.

Daily reference:

```sh
gentle-ai doctor            # health check
gentle-ai sync              # refresh managed assets (idempotent)
gentle-ai skill-registry refresh   # rebuild a project's skill registry
engram projects list        # persistent memory across sessions
opencode                    # press Tab to switch between SDD orchestrators
```

Inside OpenCode: `/sdd-init` once per project, then the `/sdd-*` workflow
commands (explore, propose, spec, design, tasks, apply, verify, archive).

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
