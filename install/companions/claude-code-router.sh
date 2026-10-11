#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Claude Code Router (musistudio) 1-Shot Native Termux Installer
# Repository: https://github.com/therealfreddied/awesome-termux-coding
# Platform: Android / Termux aarch64 (Native Bionic - No PRoot required)
# Upstream: musistudio/claude-code-router (@musistudio/claude-code-router)
# Purpose: Route Claude Code to ANY model (DeepSeek, Gemini, OpenRouter, Ollama)
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

PKG="@musistudio/claude-code-router"
log "Installing $PKG globally via npm..."
npm install -g --omit=dev --no-audit --no-fund "$PKG"

PKG_DIR="$PREFIX/lib/node_modules/@musistudio/claude-code-router"
if command -v termux-fix-shebang >/dev/null 2>&1; then
  if [ -d "$PKG_DIR/dist" ]; then
    find "$PKG_DIR" -maxdepth 3 -type f -perm /111 -exec termux-fix-shebang {} + 2>/dev/null || true
  fi
  termux-fix-shebang "$PREFIX/bin/ccr" 2>/dev/null || true
fi

# Create convenient launcher script
cat <<'EOF' > "$PREFIX/bin/claude-router"
#!/data/data/com.termux/files/usr/bin/bash
exec ccr "$@"
EOF
chmod +x "$PREFIX/bin/claude-router"

if command -v ccr >/dev/null 2>&1; then
  ok "Claude Code Router installed successfully!"
  echo ""
  echo "--------------------------------------------------------"
  echo "Commands available:"
  echo "  ccr           (or 'claude-router')"
  echo "  ccr start     (launch the local routing daemon)"
  echo "  ccr ui        (open the mobile web config dashboard)"
  echo ""
  echo "To connect Claude Code to this router:"
  echo "  export ANTHROPIC_BASE_URL=\"http://127.0.0.1:3456\""
  echo "  claude"
  echo "--------------------------------------------------------"
else
  warn "ccr binary not found in PATH ($PREFIX/bin)."
fi
