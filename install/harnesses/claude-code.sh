#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Claude Code 1-Shot Native Termux Installer
# Repository: https://github.com/therealfreddied/awesome-termux-coding
# Platform: Android / Termux aarch64 (Native Bionic - No PRoot required)
# ==============================================================================
set -euo pipefail

COLOR_INFO="\033[38;5;45m"
COLOR_SUCCESS="\033[38;5;48m"
COLOR_WARN="\033[38;5;214m"
COLOR_RESET="\033[0m"

log() { printf "${COLOR_INFO}[INFO]${COLOR_RESET} %s\n" "$*"; }
ok()  { printf "${COLOR_SUCCESS}[OK]${COLOR_RESET} %s\n" "$*"; }
warn(){ printf "${COLOR_WARN}[WARN]${COLOR_RESET} %s\n" "$*"; }

# 1. Environment & Architecture Verification
if [ ! -d "/data/data/com.termux/files/usr" ]; then
  echo "Error: This installer is intended for native execution inside Termux on Android." >&2
  exit 1
fi

ARCH="$(uname -m)"
if [ "$ARCH" != "aarch64" ]; then
  warn "Detected architecture: $ARCH. Most native binaries require aarch64 (arm64)."
fi

# 2. Existing Installation Detection (Repair / Delete / Exit)
if command -v claude >/dev/null 2>&1 || [ -d "$PREFIX/lib/node_modules/@anthropic-ai/claude-code" ]; then
  echo ""
  warn "Claude Code is already installed on this device!"
  echo "Select an option:"
  echo "  1) Repair / Reinstall"
  echo "  2) Delete / Uninstall"
  echo "  3) Exit"
  echo ""

  CHOICE=""
  if [ -t 0 ]; then
    read -rp "Enter choice [1-3] (default: 1): " CHOICE
  elif [ -e /dev/tty ]; then
    read -rp "Enter choice [1-3] (default: 1): " CHOICE < /dev/tty || CHOICE="1"
  else
    CHOICE="1"
  fi
  CHOICE="${CHOICE:-1}"

  case "$CHOICE" in
    1)
      log "Proceeding with repair / update..."
      ;;
    2)
      log "Uninstalling Claude Code..."
      npm uninstall -g @anthropic-ai/claude-code >/dev/null 2>&1 || true
      rm -f "$PREFIX/bin/claude"
      ok "Claude Code has been completely removed."
      exit 0
      ;;
    3)
      log "Exiting without making changes."
      exit 0
      ;;
    *)
      warn "Invalid choice. Exiting."
      exit 1
      ;;
  esac
fi

# 3. Dependencies
log "Verifying core dependencies..."
DEPS=""
command -v node >/dev/null 2>&1 || DEPS="$DEPS nodejs-lts"
command -v git >/dev/null 2>&1 || DEPS="$DEPS git"
command -v curl >/dev/null 2>&1 || DEPS="$DEPS curl"

if [ -n "$DEPS" ]; then
  pkg update -y >/dev/null 2>&1 || true
  pkg install -y $DEPS >/dev/null 2>&1 || pkg install -y $DEPS
fi

NPM_PREFIX="$(npm config get prefix)"
if [ "$NPM_PREFIX" != "$PREFIX" ]; then
  npm config set prefix "$PREFIX"
fi

# 4. Clean npm install
log "Installing @anthropic-ai/claude-code natively via npm..."
rm -f "$PREFIX/bin/claude"
npm install -g --omit=dev --no-audit --no-fund --loglevel=error @anthropic-ai/claude-code >/dev/null 2>&1 || \
npm install -g --omit=dev --no-audit --no-fund @anthropic-ai/claude-code

# 5. Fix Bionic shebangs
PKG_DIR="$PREFIX/lib/node_modules/@anthropic-ai/claude-code"
if command -v termux-fix-shebang >/dev/null 2>&1; then
  if [ -d "$PKG_DIR" ]; then
    find "$PKG_DIR" -maxdepth 3 -type f -perm /111 -exec termux-fix-shebang {} + 2>/dev/null || true
  fi
  termux-fix-shebang "$PREFIX/bin/claude" 2>/dev/null || true
fi

# 6. Verification
if command -v claude >/dev/null 2>&1; then
  ok "Claude Code installed and verified!"
  echo ""
  echo "--------------------------------------------------------"
  echo "Run Claude Code with:"
  echo "  claude"
  echo ""
  echo "Installed version:"
  claude --version 2>/dev/null || true
  echo "--------------------------------------------------------"
else
  warn "claude binary was not found in PATH ($PREFIX/bin)."
fi
