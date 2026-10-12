#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Google Antigravity CLI (agy) 1-Shot Native Termux Installer
# Repository: https://github.com/therealfreddied/awesome-termux-coding
# Platform: Android / Termux aarch64 (Native Bionic - VA39 Patched Standalone Port)
# Upstream: wallentx/antigravity-cli-termux (hjotha & Brajesh2022 binary patches)
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

ARCH="$(uname -m)"
if [ "$ARCH" != "aarch64" ]; then
  echo "Error: Antigravity CLI requires aarch64 (64-bit ARM). Detected: $ARCH" >&2
  exit 1
fi

# Clean up broken npm wrapper if previously installed
npm uninstall -g @kelvinzero/antigravity-cli >/dev/null 2>&1 || true

# 1. Existing Installation Detection (Repair / Delete / Exit)
if command -v agy >/dev/null 2>&1 || [ -f "$PREFIX/bin/agy" ]; then
  echo ""
  warn "Antigravity CLI (agy) is already installed on this device!"
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
      log "Uninstalling Antigravity CLI..."
      rm -f "$PREFIX/bin/agy" "$PREFIX/bin/agy.va39" "$PREFIX/bin/antigravity"
      ok "Antigravity CLI has been completely removed."
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
command -v curl >/dev/null 2>&1 || DEPS="$DEPS curl"
command -v tar >/dev/null 2>&1 || DEPS="$DEPS tar"
command -v gzip >/dev/null 2>&1 || DEPS="$DEPS gzip"

if [ -n "$DEPS" ]; then
  pkg update -y >/dev/null 2>&1 || true
  pkg install -y $DEPS >/dev/null 2>&1 || pkg install -y $DEPS
fi

# 3. Download & Install Standalone VA39-Patched Native Port
URL="https://github.com/wallentx/antigravity-cli-termux/releases/latest/download/antigravity-termux-standalone.tar.gz"
TMP_DIR="$PREFIX/tmp/.agy-install"
mkdir -p "$TMP_DIR"

log "Downloading official standalone Termux port (VA39 TCMalloc patched)..."
curl -fsSL -L "$URL" -o "$TMP_DIR/agy-standalone.tar.gz"

log "Extracting binaries into $PREFIX/bin..."
tar -xzf "$TMP_DIR/agy-standalone.tar.gz" -C "$TMP_DIR"

# Install both agy and the kernel VA39 fallback
if [ -f "$TMP_DIR/bin/agy" ]; then
  install -m 755 "$TMP_DIR/bin/agy" "$PREFIX/bin/agy"
elif [ -f "$TMP_DIR/agy" ]; then
  install -m 755 "$TMP_DIR/agy" "$PREFIX/bin/agy"
fi

if [ -f "$TMP_DIR/bin/agy.va39" ]; then
  install -m 755 "$TMP_DIR/bin/agy.va39" "$PREFIX/bin/agy.va39"
elif [ -f "$TMP_DIR/agy.va39" ]; then
  install -m 755 "$TMP_DIR/agy.va39" "$PREFIX/bin/agy.va39"
fi

# Alias 'antigravity' to 'agy'
ln -sf "$PREFIX/bin/agy" "$PREFIX/bin/antigravity"

rm -rf "$TMP_DIR"

# 4. Verification
if command -v agy >/dev/null 2>&1; then
  ok "Antigravity CLI (agy) installed and verified!"
  echo ""
  echo "--------------------------------------------------------"
  echo "Run Antigravity with:"
  echo "  agy"
  echo ""
  echo "Installed version:"
  agy --version 2>/dev/null || true
  echo "--------------------------------------------------------"
else
  warn "agy binary not found in PATH ($PREFIX/bin)."
fi
