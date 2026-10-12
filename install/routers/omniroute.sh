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

OMNI_DIR="$HOME/omniroute"

# 1. Existing Installation Detection (Repair / Delete / Exit)
if command -v omniroute >/dev/null 2>&1 || [ -d "$OMNI_DIR" ]; then
  echo ""
  warn "OmniRoute is already installed on this device!"
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
      log "Uninstalling OmniRoute..."
      rm -rf "$OMNI_DIR"
      rm -f "$PREFIX/bin/omniroute"
      ok "OmniRoute has been completely removed."
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
log "Verifying dependencies..."
DEPS=""
command -v node >/dev/null 2>&1 || DEPS="$DEPS nodejs-lts"
command -v git >/dev/null 2>&1 || DEPS="$DEPS git"
command -v curl >/dev/null 2>&1 || DEPS="$DEPS curl"

if [ -n "$DEPS" ]; then
  pkg update -y >/dev/null 2>&1 || true
  pkg install -y $DEPS >/dev/null 2>&1 || pkg install -y $DEPS
fi

SRC_URL="https://github.com/diegosouzapw/OmniRoute.git"

log "Fetching OmniRoute repository into $OMNI_DIR..."
if [ -d "$OMNI_DIR/.git" ]; then
  git -C "$OMNI_DIR" pull --ff-only >/dev/null 2>&1 || true
else
  rm -rf "$OMNI_DIR"
  git clone --depth 1 "$SRC_URL" "$OMNI_DIR" >/dev/null 2>&1
fi

cd "$OMNI_DIR"

log "Installing production dependencies (--omit=dev)..."
npm install --no-audit --no-fund --omit=dev --loglevel=error >/dev/null 2>&1 || \
npm install --no-audit --no-fund --omit=dev

# Termux launcher wrapper
rm -f "$PREFIX/bin/omniroute"
cat <<'EOF' > "$PREFIX/bin/omniroute"
#!/data/data/com.termux/files/usr/bin/bash
OMNI_DIR="$HOME/omniroute"
export PORT="${PORT:-20128}"
export NODE_OPTIONS="${NODE_OPTIONS:---max-old-space-size=1024}"
cd "$OMNI_DIR"
exec node dist/server.js "$@" 2>/dev/null || exec npm start -- "$@"
EOF
chmod 755 "$PREFIX/bin/omniroute"
termux-fix-shebang "$PREFIX/bin/omniroute" 2>/dev/null || true

# 3. Verification
if command -v omniroute >/dev/null 2>&1; then
  ok "OmniRoute Lite installed and verified!"
  echo ""
  echo "--------------------------------------------------------"
  echo "Launch OmniRoute with:"
  echo "  omniroute"
  echo "--------------------------------------------------------"
else
  warn "omniroute binary not found on PATH."
fi
