#!/usr/bin/env bash
#
# install.sh - report which packages from packages.list are NOT installed.
#
# This script never installs anything. It detects the package manager,
# checks each package in packages.list against the system, and prints:
#   1. The missing packages (one per line, easy for an AI agent to consume)
#   2. The full install command for the detected manager (if any)
#
# Usage:
#   install.sh
#   install.sh --check   fast check, exits 0 if everything is installed

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_FILE="$REPO_DIR/packages.list"

[[ -f "$PACKAGES_FILE" ]] || {
	echo "packages.list not found next to install.sh" >&2
	exit 1
}

# Read the list, ignoring comments and empty lines
mapfile -t PACKAGES < <(grep -vE '^\s*(#|$)' "$PACKAGES_FILE")

detect_manager() {
	if command -v pacman >/dev/null 2>&1; then
		echo "pacman"
	elif command -v dnf >/dev/null 2>&1; then
		echo "dnf"
	elif command -v apt-get >/dev/null 2>&1; then
		echo "apt"
	else
		echo "unknown"
	fi
}

is_installed() {
	local pkg="$1"
	case "$MANAGER" in
		pacman) pacman -Qi "$pkg" >/dev/null 2>&1 ;;
		dnf) rpm -q "$pkg" >/dev/null 2>&1 ;;
		apt) dpkg -s "$pkg" >/dev/null 2>&1 ;;
		*) return 1 ;;
	esac
}

MANAGER="$(detect_manager)"
echo "package manager detected: $MANAGER"

MISSING=()
for pkg in "${PACKAGES[@]}"; do
	if ! is_installed "$pkg"; then
		MISSING+=("$pkg")
	fi
done

if [[ "${#MISSING[@]}" -eq 0 ]]; then
	echo "everything in packages.list is installed."
	exit 0
fi

echo ""
echo "missing packages (${#MISSING[@]}):"
printf '%s\n' "${MISSING[@]}"

echo ""
case "$MANAGER" in
	pacman) echo "install command: sudo pacman -S --needed ${MISSING[*]}" ;;
	dnf) echo "install command: sudo dnf install ${MISSING[*]}" ;;
	apt) echo "install command: sudo apt install ${MISSING[*]}" ;;
	*) echo "no known package manager; install manually: ${MISSING[*]}" ;;
esac

exit 1