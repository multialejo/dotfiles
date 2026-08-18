#!/usr/bin/env bash
#
# apply.sh - symlink configs from this repo into the home directory.
#
# Usage:
#   apply.sh [--dry-run] [--force]
#
# Symlinks every app in config/* to ~/.config/<app> and the dotfiles
# (config/.bashrc, config/.bash_profile) to ~/. Idempotent: re-running
# is safe. Existing real files are never overwritten (unless --force).

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

HOME_DOTFILES=(
	".bashrc"
	".bash_profile"
	".bash-omarchy"
	".inputrc"
)

link() {
	local source="$1" target="$2"

	if [[ -e "$target" && ! -L "$target" ]]; then
		if [[ "$FORCE" -eq 1 ]]; then
			echo "replacing real file: $target"
			if [[ "$DRY_RUN" -eq 0 ]]; then
				rm "$target"
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
	link "$app" "$CONFIG_TARGET/$name"
done

for dotfile in "${HOME_DOTFILES[@]}"; do
	[[ -f "$CONFIG_DIR/$dotfile" ]] || continue
	link "$CONFIG_DIR/$dotfile" "$HOME/$dotfile"
done

echo "done."