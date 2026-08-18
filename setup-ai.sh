#!/usr/bin/env bash
#
# setup-ai.sh - bootstrap the Gentle-AI ecosystem (OpenCode + Engram + SDD +
# skills + Context7 + GGA) for any supported Linux distro.
#
# Usage:
#   setup-ai.sh                 full setup (installs opencode/gentle-ai if missing)
#   setup-ai.sh --dry-run       preview every step without touching anything
#   setup-ai.sh --persona neutral   persona override (default: gentleman)
#   setup-ai.sh --yes           auto-accept installs without prompting
#
# Idempotent: safe to re-run at any time; re-running reconciles the ecosystem
# with the installed gentle-ai version (assets are tied to the binary version).
#
# Steps:
#   1. Check prerequisites (git, curl, node >= 18, npm); print the exact
#      install command for the detected package manager when something is missing
#   2. Install opencode globally via npm if missing
#   3. Install gentle-ai via the official installer if missing
#   4. gentle-ai install --agent opencode --preset full-gentleman
#   5. Ensure the opencode-go provider block exists in opencode.json (the SDD
#      model profiles reference its models)
#   6. Create the SDD model profiles (free-explore / free-design / free-impl /
#      free-verify)
#   7. gentle-ai sync + gentle-ai doctor health check
#
# Notes:
#   - gentle-ai manages ~/.config/opencode itself (prompts, agents, skills,
#     permissions). This script never symlinks or copies those files; run
#     `gentle-ai sync` after every `gentle-ai upgrade` instead.
#   - Community plugins (opencode-subagent-statusline, sdd-engram-plugin) are
#     NOT installed here for determinism; add them via the gentle-ai TUI.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DRY_RUN=0
YES=0
PERSONA="gentleman"

# --- Configurable models (provider + model IDs from opencode.json) ----------
PROVIDER="opencode-go"
MODEL_BASE="qwen3.7-plus"
MODEL_DESIGN="deepseek-v4-pro"
MODEL_IMPL="kimi-k2.7-code"
MODEL_VERIFY="qwen3.7-max"

OPENCODE_CONFIG="$HOME/.config/opencode/opencode.json"

# --- CLI options ------------------------------------------------------------

i=0
args=("$@")
while [[ $i -lt "${#args[@]}" ]]; do
	arg="${args[$i]}"
	case "$arg" in
		--dry-run)
			DRY_RUN=1
			;;
		--yes)
			YES=1
			;;
		--persona)
			i=$((i + 1))
			if [[ $i -ge "${#args[@]}" ]]; then
				echo "--persona requires a value (neutral|gentleman)" >&2
				exit 1
			fi
			PERSONA="${args[$i]}"
			;;
		--persona=*)
			PERSONA="${arg#*=}"
			;;
		*)
			echo "Unknown option: $arg" >&2
			echo "Usage: $0 [--dry-run] [--yes] [--persona neutral|gentleman]" >&2
			exit 1
			;;
	esac
	i=$((i + 1))
done

case "$PERSONA" in
	neutral|gentleman) ;;
	*)
		echo "Unknown persona: $PERSONA (use neutral or gentleman)" >&2
		exit 1
		;;
esac

# --- Helpers ----------------------------------------------------------------

log()  { echo "==> $*"; }
warn() { echo "!!  $*" >&2; }

confirm() {
	local msg="$1"
	[[ "$YES" -eq 1 ]] && return 0
	echo ""
	read -r -p "?  $msg [y/N] " answer
	[[ "${answer,,}" == "y" || "${answer,,}" == "yes" ]]
}

run() {
	if [[ "$DRY_RUN" -eq 1 ]]; then
		echo "would run: $*"
	else
		"$@"
	fi
}

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

install_hint() {
	local missing="$1"
	local mgr
	mgr="$(detect_manager)"
	case "$mgr" in
		pacman) echo "install command: sudo pacman -S --needed $missing" ;;
		dnf) echo "install command: sudo dnf install $missing" ;;
		apt) echo "install command: sudo apt install $missing" ;;
		*) echo "no known package manager; install manually: $missing" ;;
	esac
}

# Resolve the gentle-ai binary wherever the installer dropped it
find_gentle_ai() {
	if command -v gentle-ai >/dev/null 2>&1; then
		command -v gentle-ai
	elif [[ -x "$HOME/.local/bin/gentle-ai" ]]; then
		echo "$HOME/.local/bin/gentle-ai"
	elif [[ -x "$HOME/.gentle-ai/bin/gentle-ai" ]]; then
		echo "$HOME/.gentle-ai/bin/gentle-ai"
	fi
}

GA="$(find_gentle_ai || true)"

# --- Step 1: prerequisites --------------------------------------------------

log "Checking prerequisites"
MISSING=()
for tool in git curl; do
	command -v "$tool" >/dev/null 2>&1 || MISSING+=("$tool")
done

if ! command -v node >/dev/null 2>&1; then
	MISSING+=("nodejs")
elif ! node -e "process.exit(Number(process.versions.node.split('.')[0]) >= 18 ? 0 : 1)" 2>/dev/null; then
	warn "node $(node --version) is too old; gentle-ai requires Node.js >= 18"
	exit 1
fi

command -v npm >/dev/null 2>&1 || MISSING+=("npm")

if [[ "${#MISSING[@]}" -gt 0 ]]; then
	warn "missing prerequisites: ${MISSING[*]}"
	install_hint "${MISSING[*]}"
	exit 1
fi
log "prerequisites OK (git, curl, node $(node --version), npm $(npm --version))"

# --- Step 2: opencode -------------------------------------------------------

if command -v opencode >/dev/null 2>&1; then
	log "opencode already installed ($(opencode --version 2>/dev/null || echo present))"
else
	log "opencode not found"
	if [[ "$DRY_RUN" -eq 1 ]]; then
		log "would install: sudo npm install -g opencode-ai"
	elif confirm "install opencode globally via npm (needs sudo)?"; then
		sudo npm install -g opencode-ai
	else
		warn "opencode is required; install it with: sudo npm install -g opencode-ai"
		exit 1
	fi
fi

# --- Step 3: gentle-ai ------------------------------------------------------

if [[ -n "$GA" ]]; then
	log "gentle-ai already installed ($($GA --version 2>/dev/null || echo present))"
else
	log "gentle-ai not found"
	if [[ "$DRY_RUN" -eq 1 ]]; then
		log "would install via official script: curl -fsSL https://raw.githubusercontent.com/Gentleman-Programming/gentle-ai/main/scripts/install.sh | bash"
	elif confirm "install gentle-ai via the official installer?"; then
		curl -fsSL https://raw.githubusercontent.com/Gentleman-Programming/gentle-ai/main/scripts/install.sh | bash
		GA="$(find_gentle_ai)"
		if [[ -z "$GA" ]]; then
			warn "gentle-ai installed but not on PATH; add ~/.local/bin to PATH or open a new shell"
			exit 1
		fi
	else
		warn "gentle-ai is required to continue"
		exit 1
	fi
fi

# --- Step 4: gentle-ai install (idempotent reconcile) -----------------------

log "Running gentle-ai install (agent=opencode, preset=full-gentleman, persona=$PERSONA, scope=global)"
run env GENTLE_AI_YES=1 "$GA" install \
	--agent opencode \
	--preset full-gentleman \
	--persona "$PERSONA" \
	--scope global

# --- Step 5: ensure the opencode-go provider block --------------------------
# The SDD profiles reference provider/model IDs (opencode-go/qwen3.7-plus).
# gentle-ai does not manage providers, so add the block on first setup.

log "Ensuring the $PROVIDER provider block exists in $OPENCODE_CONFIG"
if [[ -f "$OPENCODE_CONFIG" ]] && grep -q "\"$PROVIDER\"" "$OPENCODE_CONFIG"; then
	log "provider $PROVIDER already configured"
else
	FRAGMENT=$(cat <<'JSON'
{
  "provider": {
    "opencode-go": {
      "npm": "@opencode-ai/provider",
      "name": "OpenCode Go",
      "options": {},
      "models": {
        "deepseek-v4-flash": { "name": "DeepSeek V4 Flash" },
        "deepseek-v4-pro": { "name": "DeepSeek V4 Pro" },
        "glm-5.1": { "name": "GLM-5.1" },
        "glm-5.2": { "name": "GLM-5.2" },
        "kimi-k2.6": { "name": "Kimi K2.6" },
        "kimi-k2.7-code": { "name": "Kimi K2.7 Code" },
        "mimo-v2.5": { "name": "MiMo V2.5" },
        "mimo-v2.5-pro": { "name": "MiMo V2.5 Pro" },
        "qwen3.6-plus": { "name": "Qwen3.6 Plus" },
        "qwen3.7-max": { "name": "Qwen3.7 Max" },
        "qwen3.7-plus": { "name": "Qwen3.7 Plus" }
      }
    }
  }
}
JSON
	)
	if [[ "$DRY_RUN" -eq 1 ]]; then
		log "would merge the $PROVIDER provider block into $OPENCODE_CONFIG"
	else
		if [[ ! -f "$OPENCODE_CONFIG" ]]; then
			warn "$OPENCODE_CONFIG not found (gentle-ai install should have created it)"
			exit 1
		fi
		cp "$OPENCODE_CONFIG" "$OPENCODE_CONFIG.setup-ai.bak"
		node -e '
			const fs = require("fs");
			const cfgPath = process.argv[1];
			const fragment = JSON.parse(process.argv[2]);
			const cfg = JSON.parse(fs.readFileSync(cfgPath, "utf8"));
			cfg.provider = Object.assign({}, cfg.provider, fragment.provider);
			fs.writeFileSync(cfgPath, JSON.stringify(cfg, null, 2) + "\n");
		' "$OPENCODE_CONFIG" "$FRAGMENT"
		log "provider $PROVIDER merged (backup: $OPENCODE_CONFIG.setup-ai.bak)"
	fi
fi

# --- Step 6: SDD model profiles ---------------------------------------------

log "Creating SDD model profiles"
run "$GA" sync --profile "free-explore:${PROVIDER}/${MODEL_BASE}"
run "$GA" sync \
	--profile "free-design:${PROVIDER}/${MODEL_BASE}" \
	--profile-phase "free-design:sdd-design:${PROVIDER}/${MODEL_DESIGN}"
run "$GA" sync \
	--profile "free-impl:${PROVIDER}/${MODEL_BASE}" \
	--profile-phase "free-impl:sdd-apply:${PROVIDER}/${MODEL_IMPL}"
run "$GA" sync \
	--profile "free-verify:${PROVIDER}/${MODEL_BASE}" \
	--profile-phase "free-verify:sdd-verify:${PROVIDER}/${MODEL_VERIFY}"

# --- Step 7: final sync + health check --------------------------------------

log "Syncing managed assets"
run "$GA" sync

log "Health check"
run "$GA" doctor

log ""
log "Done. Open an AI agent session in a project and:"
log "  - press Tab inside OpenCode to switch between the 5 orchestrators"
log "  - run /sdd-init in each project to bootstrap SDD context"
log "  - refresh the skill registry with: gentle-ai skill-registry refresh"
