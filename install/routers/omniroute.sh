#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# OmniRoute (Native Lite Backend) 1-Shot Termux Installer
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

log "Verifying dependencies..."
DEPS=""
command -v node >/dev/null 2>&1 || DEPS="$DEPS nodejs-lts"
command -v git >/dev/null 2>&1 || DEPS="$DEPS git"
command -v curl >/dev/null 2>&1 || DEPS="$DEPS curl"

if [ -n "$DEPS" ]; then
  pkg update -y >/dev/null 2>&1 || true
  pkg install -y $DEPS
fi

OMNI_DIR="$HOME/omniroute"
SRC_URL="https://github.com/diegosouzapw/OmniRoute.git"

log "Fetching OmniRoute repository into $OMNI_DIR..."
if [ -d "$OMNI_DIR/.git" ]; then
  git -C "$OMNI_DIR" pull --ff-only || true
else
  rm -rf "$OMNI_DIR"
  git clone --depth 1 "$SRC_URL" "$OMNI_DIR"
fi

cd "$OMNI_DIR"

log "Installing production dependencies (--omit=dev)..."
npm install --no-audit --no-fund --omit=dev

# Termux-safe launcher wrapper: binds API backend on port 20128
cat <<'EOF' > "$PREFIX/bin/omniroute"
#!/data/data/com.termux/files/usr/bin/bash
OMNI_DIR="$HOME/omniroute"
export PORT="${PORT:-20128}"
export NODE_OPTIONS="${NODE_OPTIONS:---max-old-space-size=1024}"
cd "$OMNI_DIR"
exec node dist/server.js "$@" 2>/dev/null || exec npm start -- "$@"
EOF
chmod +x "$PREFIX/bin/omniroute"

ok "OmniRoute Lite installed successfully!"
echo ""
echo "--------------------------------------------------------"
echo "Launch your personal router:"
echo "  omniroute"
echo ""
echo "Default port: 20128"
echo "Point your harnesses to: http://127.0.0.1:20128/v1"
echo "--------------------------------------------------------"
