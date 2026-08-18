#!/usr/bin/env bash
#
# apply.sh - symlink configs from this repo into the home directory.
#
# Usage:
#   apply.sh [--dry-run] [--force]
#
# Symlinks every app in config/* to ~/.config/<app> and the dotfiles
# (config/.bashrc, config/.bash_profile, ...) to ~. Idempotent: re-running
# is safe. Existing real files are never overwritten (unless --force).
#
# Omarchy-aware: on machines where Omarchy is installed
# (~/.local/share/omarchy exists), the entries Omarchy manages (.bashrc,
# kitty, tmux) are always skipped - Omarchy owns them and re-copies its
# upstream versions on every update. Symlinking them would let Omarchy's
# cp write through the link and clobber the repo. --force does not
# override this; it only replaces real files Omarchy does not manage.

set -euo pipefail

DRY_RUN=0
FORCE=0

for arg in "$@"; do
	case "$arg" in
		--dry-run) DRY_RUN=1 ;;
		--force) FORCE=1 ;;
		*)
			echo "Unknown option: $arg" >&2
			echo "Usage: $0 [--dry-run] [--force]" >&2
			exit 1
			;;
	esac
done

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$REPO_DIR/config"
CONFIG_TARGET="$HOME/.config"

# Entries managed by Omarchy (re-copied from upstream on every update)
OMARCHY_MANAGED=(
	".bashrc"
	"kitty"
	"tmux"
)

OMARCHY_PRESENT=0
if [[ -d "$HOME/.local/share/omarchy" ]]; then
	OMARCHY_PRESENT=1
	echo "Omarchy detected - skipping its managed entries: $(IFS=', '; echo "${OMARCHY_MANAGED[*]}")"
fi

HOME_DOTFILES=(
	".bashrc"
	".bash_profile"
	".bash-omarchy"
	".inputrc"
)

is_omarchy_managed() {
	local name="$1"
	local entry
	for entry in "${OMARCHY_MANAGED[@]}"; do
		[[ "$entry" == "$name" ]] && return 0
	done
	return 1
}

link() {
	local source="$1" target="$2" name

	if [[ -e "$target" && ! -L "$target" ]]; then
		if [[ "$FORCE" -eq 1 ]]; then
			echo "replacing real file: $target"
			if [[ "$DRY_RUN" -eq 0 ]]; then
				rm -rf "$target"
			fi
		else
			echo "skipping (real file exists, use --force): $target"
			return
		fi
	fi

	echo "linking $target -> $source"
	if [[ "$DRY_RUN" -eq 0 ]]; then
		ln -sfn "$source" "$target"
	fi
}

mkdir -p "$CONFIG_TARGET"

for app in "$CONFIG_DIR"/*/; do
	name="$(basename "$app")"
	if [[ "$OMARCHY_PRESENT" -eq 1 ]] && is_omarchy_managed "$name"; then
		echo "skipping (managed by Omarchy): $name"
		continue
	fi
	link "$app" "$CONFIG_TARGET/$name"
done

for dotfile in "${HOME_DOTFILES[@]}"; do
	[[ -f "$CONFIG_DIR/$dotfile" ]] || continue
	if [[ "$OMARCHY_PRESENT" -eq 1 ]] && is_omarchy_managed "$dotfile"; then
		echo "skipping (managed by Omarchy): $dotfile"
		continue
	fi
	link "$CONFIG_DIR/$dotfile" "$HOME/$dotfile"
done

echo "done."