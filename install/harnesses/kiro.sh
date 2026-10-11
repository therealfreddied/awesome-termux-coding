#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Kiro / Kilo Code CLI 1-Shot Native Termux Installer
# Repository: https://github.com/therealfreddied/awesome-termux-coding
# Platform: Android / Termux aarch64 (Native Bionic / musl loader)
# Upstream: @kilocode/cli-linux-arm64-musl
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

log "Verifying core dependencies..."
DEPS=""
command -v node >/dev/null 2>&1 || DEPS="$DEPS nodejs-lts"
command -v git >/dev/null 2>&1 || DEPS="$DEPS git"
command -v curl >/dev/null 2>&1 || DEPS="$DEPS curl"
command -v patchelf >/dev/null 2>&1 || DEPS="$DEPS patchelf"

if [ -n "$DEPS" ]; then
  pkg update -y >/dev/null 2>&1 || true
  pkg install -y $DEPS
fi

NPM_PREFIX="$(npm config get prefix)"
if [ "$NPM_PREFIX" != "$PREFIX" ]; then
  npm config set prefix "$PREFIX"
fi

PKG="@kilocode/cli"
log "Installing $PKG globally via npm..."
npm install -g --omit=dev --no-audit --no-fund "$PKG" || {
  log "Falling back to standalone binary wrapper..."
  npm install -g --omit=dev --no-audit --no-fund @kilocode/cli-linux-arm64-musl || true
}

PKG_DIR="$PREFIX/lib/node_modules/@kilocode/cli"
if command -v termux-fix-shebang >/dev/null 2>&1; then
  if [ -d "$PKG_DIR" ]; then
    find "$PKG_DIR" -maxdepth 3 -type f -perm /111 -exec termux-fix-shebang {} + 2>/dev/null || true
  fi
  termux-fix-shebang "$PREFIX/bin/kilo" 2>/dev/null || true
  termux-fix-shebang "$PREFIX/bin/kiro" 2>/dev/null || true
fi

# Ensure 'kiro' alias exists if only 'kilo' is present
if [ -f "$PREFIX/bin/kilo" ] && [ ! -f "$PREFIX/bin/kiro" ]; then
  ln -sf "$PREFIX/bin/kilo" "$PREFIX/bin/kiro"
fi

ok "Kiro / Kilo CLI installed successfully!"
echo ""
echo "--------------------------------------------------------"
echo "Run with:"
echo "  kiro"
echo "  or"
echo "  kilo"
echo "--------------------------------------------------------"
