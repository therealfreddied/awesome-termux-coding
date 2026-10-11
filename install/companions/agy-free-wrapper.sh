#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Antigravity CLI Custom Models Wrapper
# Repository: https://github.com/therealfreddied/awesome-termux-coding
# Platform: Android / Termux aarch64 (Native Bionic - No PRoot required)
# Upstream: kelvinzer0/antigravity-cli (@kelvinzero/antigravity-cli)
# Purpose: Enables OpenAI, Claude, Ollama, DeepSeek & OpenRouter in agy CLI
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

if [ -n "$DEPS" ]; then
  pkg update -y >/dev/null 2>&1 || true
  pkg install -y $DEPS
fi

NPM_PREFIX="$(npm config get prefix)"
if [ "$NPM_PREFIX" != "$PREFIX" ]; then
  npm config set prefix "$PREFIX"
fi

PKG="@kelvinzero/antigravity-cli"
log "Installing $PKG globally via npm..."
npm install -g --omit=dev --no-audit --no-fund "$PKG"

PKG_DIR="$PREFIX/lib/node_modules/@kelvinzero/antigravity-cli"
if command -v termux-fix-shebang >/dev/null 2>&1; then
  if [ -d "$PKG_DIR/dist" ]; then
    find "$PKG_DIR" -maxdepth 3 -type f -perm /111 -exec termux-fix-shebang {} + 2>/dev/null || true
  fi
  termux-fix-shebang "$PREFIX/bin/antigravity" 2>/dev/null || true
fi

# Ensure 'agy' shortcut
if [ -f "$PREFIX/bin/antigravity" ] && [ ! -f "$PREFIX/bin/agy" ]; then
  ln -sf "$PREFIX/bin/antigravity" "$PREFIX/bin/agy"
fi

ok "Antigravity Custom Provider Engine installed!"
echo ""
echo "--------------------------------------------------------"
echo "To configure your custom provider:"
echo "  agy --provider openrouter --api-key <YOUR_KEY>"
echo "  or edit ~/.antigravity/config.json"
echo ""
echo "Run with:"
echo "  agy"
echo "--------------------------------------------------------"
