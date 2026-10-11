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

# 2. Dependencies
log "Verifying core dependencies..."
DEPS=""
command -v node >/dev/null 2>&1 || DEPS="$DEPS nodejs-lts"
command -v git >/dev/null 2>&1 || DEPS="$DEPS git"
command -v curl >/dev/null 2>&1 || DEPS="$DEPS curl"

if [ -n "$DEPS" ]; then
  log "Installing missing packages:$DEPS..."
  pkg update -y >/dev/null 2>&1 || true
  pkg install -y $DEPS
fi

# 3. Global npm prefix verification
NPM_PREFIX="$(npm config get prefix)"
if [ "$NPM_PREFIX" != "$PREFIX" ]; then
  log "Setting npm prefix to $PREFIX..."
  npm config set prefix "$PREFIX"
fi

# 4. Install official Claude Code CLI
log "Installing @anthropic-ai/claude-code natively via npm..."
npm install -g --omit=dev --no-audit --no-fund @anthropic-ai/claude-code

# 5. Fix Bionic shebangs
log "Patching Bionic shebangs..."
PKG_DIR="$PREFIX/lib/node_modules/@anthropic-ai/claude-code"
if command -v termux-fix-shebang >/dev/null 2>&1; then
  if [ -d "$PKG_DIR" ]; then
    find "$PKG_DIR" -maxdepth 3 -type f -perm /111 -exec termux-fix-shebang {} + 2>/dev/null || true
  fi
  termux-fix-shebang "$PREFIX/bin/claude" 2>/dev/null || true
fi

# 6. Verification
if command -v claude >/dev/null 2>&1; then
  ok "Claude Code installed successfully!"
  echo ""
  echo "--------------------------------------------------------"
  echo "Run Claude Code with:"
  echo "  claude"
  echo ""
  echo "To use custom endpoints (OpenRouter, DeepSeek, Local Proxy):"
  echo "  export ANTHROPIC_BASE_URL=\"http://127.0.0.1:3456\""
  echo "  export ANTHROPIC_API_KEY=\"your_key_here\""
  echo "--------------------------------------------------------"
else
  warn "claude binary was not found in PATH ($PREFIX/bin). Ensure $PREFIX/bin is in your PATH."
fi
