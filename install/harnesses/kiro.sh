#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Kiro / Kilo Code CLI 1-Shot Native Termux Installer
# Repository: https://github.com/therealfreddied/awesome-termux-coding
# Platform: Android / Termux aarch64 (Native Bionic / musl loader)
# ==============================================================================
set -euo pipefail

COLOR_INFO="\033[38;5;45m"
COLOR_SUCCESS="\033[38;5;48m"
COLOR_WARN="\033[38;5;214m"
COLOR_RESET="\033[0m"

log() { printf "${COLOR_INFO}[INFO]${COLOR_RESET} %s\n" "$*"; }
ok()  { printf "${COLOR_SUCCESS}[OK]${COLOR_RESET} %s\n" "$*"; }
warn(){ printf "${COLOR_WARN}[WARN]${COLOR_RESET} %s\n" "$*"; }

if [ ! -d "/data/data/com.termux/files/usr" ]; then
  echo "Error: This installer is intended for native execution inside Termux on Android." >&2
  exit 1
fi

PKG="@kilocode/cli"

# 1. Existing Installation Detection (Repair / Delete / Exit)
if command -v kiro >/dev/null 2>&1 || command -v kilo >/dev/null 2>&1 || [ -d "$PREFIX/lib/node_modules/$PKG" ]; then
  echo ""
  warn "Kiro / Kilo CLI is already installed on this device!"
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
      log "Uninstalling Kiro / Kilo CLI..."
      npm uninstall -g "$PKG" @kilocode/cli-linux-arm64-musl >/dev/null 2>&1 || true
      rm -f "$PREFIX/bin/kiro" "$PREFIX/bin/kilo"
      ok "Kiro / Kilo CLI has been completely removed."
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

# 2. Dependencies
log "Verifying core dependencies..."
DEPS=""
command -v node >/dev/null 2>&1 || DEPS="$DEPS nodejs-lts"
command -v git >/dev/null 2>&1 || DEPS="$DEPS git"
command -v curl >/dev/null 2>&1 || DEPS="$DEPS curl"
command -v patchelf >/dev/null 2>&1 || DEPS="$DEPS patchelf"

if [ -n "$DEPS" ]; then
  pkg update -y >/dev/null 2>&1 || true
  pkg install -y $DEPS >/dev/null 2>&1 || pkg install -y $DEPS
fi

NPM_PREFIX="$(npm config get prefix)"
if [ "$NPM_PREFIX" != "$PREFIX" ]; then
  npm config set prefix "$PREFIX"
fi

# 3. Clean npm install
log "Installing $PKG globally via npm..."
rm -f "$PREFIX/bin/kiro" "$PREFIX/bin/kilo"
npm install -g --omit=dev --no-audit --no-fund --loglevel=error "$PKG" >/dev/null 2>&1 || {
  npm install -g --omit=dev --no-audit --no-fund --loglevel=error @kilocode/cli-linux-arm64-musl >/dev/null 2>&1 || true
}

PKG_DIR="$PREFIX/lib/node_modules/@kilocode/cli"
if command -v termux-fix-shebang >/dev/null 2>&1; then
  if [ -d "$PKG_DIR" ]; then
    find "$PKG_DIR" -maxdepth 3 -type f -perm /111 -exec termux-fix-shebang {} + 2>/dev/null || true
  fi
  termux-fix-shebang "$PREFIX/bin/kilo" 2>/dev/null || true
  termux-fix-shebang "$PREFIX/bin/kiro" 2>/dev/null || true
fi

# Alias kiro <-> kilo
if [ -f "$PREFIX/bin/kilo" ] && [ ! -f "$PREFIX/bin/kiro" ]; then
  ln -sf "$PREFIX/bin/kilo" "$PREFIX/bin/kiro"
fi

# 4. Verification
if command -v kiro >/dev/null 2>&1 || command -v kilo >/dev/null 2>&1; then
  ok "Kiro / Kilo CLI installed and verified!"
  echo ""
  echo "--------------------------------------------------------"
  echo "Run with:"
  echo "  kiro"
  echo "  or"
  echo "  kilo"
  echo "--------------------------------------------------------"
else
  warn "kiro / kilo binary not found in PATH."
fi
