#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# OpenCodex 1-Shot Native Termux Installer
# Repository: https://github.com/therealfreddied/awesome-termux-coding
# Platform: Android / Termux aarch64 (Native Bionic - No PRoot required)
# Upstream: lidge-jun/opencodex (published as @bitkyc08/opencodex)
# Purpose: Universal provider proxy for OpenAI Codex CLI (use Claude, Gemini,
#          DeepSeek, Ollama, OpenRouter with Codex)
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
  log "Installing missing packages:$DEPS..."
  pkg update -y >/dev/null 2>&1 || true
  pkg install -y $DEPS
fi

NPM_PREFIX="$(npm config get prefix)"
if [ "$NPM_PREFIX" != "$PREFIX" ]; then
  npm config set prefix "$PREFIX"
fi

PKG="@bitkyc08/opencodex"
log "Installing $PKG natively via npm..."
npm install -g --omit=dev --no-audit --no-fund "$PKG"

PKG_DIR="$PREFIX/lib/node_modules/@bitkyc08/opencodex"
if command -v termux-fix-shebang >/dev/null 2>&1; then
  if [ -d "$PKG_DIR/bin" ]; then
    find "$PKG_DIR/bin" -maxdepth 2 -type f -perm /111 -exec termux-fix-shebang {} + 2>/dev/null || true
  fi
  termux-fix-shebang "$PREFIX/bin/ocx" 2>/dev/null || true
  termux-fix-shebang "$PREFIX/bin/opencodex" 2>/dev/null || true
fi

if command -v ocx >/dev/null 2>&1 || command -v opencodex >/dev/null 2>&1; then
  ok "OpenCodex installed successfully!"
  echo ""
  echo "--------------------------------------------------------"
  echo "Commands available:"
  echo "  ocx           (or 'opencodex')"
  echo "  ocx --help    (view provider configuration options)"
  echo ""
  echo "Bridge any model (Claude, DeepSeek, Ollama) into Codex CLI!"
  echo "--------------------------------------------------------"
else
  warn "ocx binary not found in PATH ($PREFIX/bin)."
fi
