#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# DeepSeek Harness (dsh) 1-Shot Native Termux Installer
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

if [ ! -d "/data/data/com.termux/files/usr" ]; then
  echo "Error: This installer is intended for native execution inside Termux on Android." >&2
  exit 1
fi

log "Verifying core dependencies..."
DEPS=""
command -v node >/dev/null 2>&1 || DEPS="$DEPS nodejs-lts"
command -v git >/dev/null 2>&1 || DEPS="$DEPS git"
command -v curl >/dev/null 2>&1 || DEPS="$DEPS curl"
command -v tar >/dev/null 2>&1 || DEPS="$DEPS tar"

if [ -n "$DEPS" ]; then
  pkg update -y >/dev/null 2>&1 || true
  pkg install -y $DEPS
fi

TMP_DIR="$PREFIX/tmp/dsh-install"
DEST_DIR="$PREFIX/opt/dsh"
mkdir -p "$TMP_DIR" "$DEST_DIR"

log "Fetching native DeepSeek Harness Termux build..."
RELEASE_URL="https://github.com/Vengisk/deepseek-harness-termux/releases/latest/download/dsh-termux-aarch64.tar.gz"

if curl -fsSL -I "$RELEASE_URL" >/dev/null 2>&1; then
  curl -fsSL -L "$RELEASE_URL" -o "$TMP_DIR/dsh.tar.gz"
  tar -xzf "$TMP_DIR/dsh.tar.gz" -C "$DEST_DIR"
else
  log "Installing @deepseek-ai/dsh via npm with native shims..."
  npm install -g --omit=dev --no-audit --no-fund @deepseek-ai/dsh || {
    npm install -g --omit=dev --no-audit --no-fund deepseek-ai
  }
fi

if command -v termux-fix-shebang >/dev/null 2>&1; then
  termux-fix-shebang "$PREFIX/bin/dsh" 2>/dev/null || true
fi

rm -rf "$TMP_DIR"

if command -v dsh >/dev/null 2>&1; then
  ok "DeepSeek Harness installed successfully!"
  echo ""
  echo "--------------------------------------------------------"
  echo "Run DeepSeek Harness with:"
  echo "  dsh"
  echo ""
  echo "Configure your DeepSeek API key:"
  echo "  export DEEPSEEK_API_KEY=\"sk-...\""
  echo "--------------------------------------------------------"
else
  warn "dsh binary not found in PATH ($PREFIX/bin)."
fi
