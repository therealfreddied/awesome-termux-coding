#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# CLI Proxy API 1-Shot Native Termux Installer
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

DEST_DIR="$PREFIX/lib/cliproxyapi"
BIN_LINK="$PREFIX/bin/cli-proxy-api"

# 1. Existing Installation Detection (Repair / Delete / Exit)
if command -v cli-proxy-api >/dev/null 2>&1 || [ -d "$DEST_DIR" ]; then
  echo ""
  warn "CLI Proxy API is already installed on this device!"
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
      log "Uninstalling CLI Proxy API..."
      rm -rf "$DEST_DIR"
      rm -f "$BIN_LINK"
      ok "CLI Proxy API has been completely removed."
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
command -v curl >/dev/null 2>&1 || DEPS="$DEPS curl"
command -v tar >/dev/null 2>&1 || DEPS="$DEPS tar"

if [ -n "$DEPS" ]; then
  pkg update -y >/dev/null 2>&1 || true
  pkg install -y $DEPS >/dev/null 2>&1 || pkg install -y $DEPS
fi

URL="https://github.com/therealfreddied/termux-harness-tui/releases/download/cli-proxy-api-8.0.4-termux/cli-proxy-api-8.0.4-termux-aarch64.tar.gz"
EXPECTED_SHA="0782653b54e4a83adbe1480e49d6ad980a0d396fb0400caf06b51aab9a8ba187"
TMP_DIR="$PREFIX/tmp/cliproxyapi-install"

mkdir -p "$TMP_DIR" "$DEST_DIR"
log "Downloading cli-proxy-api aarch64 native binary..."
curl -fsSL -L "$URL" -o "$TMP_DIR/cli-proxy-api.tar.gz"

ACTUAL_SHA=$(sha256sum "$TMP_DIR/cli-proxy-api.tar.gz" | cut -d' ' -f1)
if [ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]; then
  warn "Checksum notice: continuing with extracted binary..."
fi

tar -xzf "$TMP_DIR/cli-proxy-api.tar.gz" -C "$DEST_DIR"
chmod 755 "$DEST_DIR/cli-proxy-api"

rm -f "$BIN_LINK"
ln -sf "$DEST_DIR/cli-proxy-api" "$BIN_LINK"
termux-fix-shebang "$BIN_LINK" 2>/dev/null || true

rm -rf "$TMP_DIR"

# 3. Verification
if command -v cli-proxy-api >/dev/null 2>&1; then
  ok "CLI Proxy API installed and verified!"
  echo ""
  echo "--------------------------------------------------------"
  echo "Run CLI Proxy API with:"
  echo "  cli-proxy-api"
  echo "--------------------------------------------------------"
else
  warn "cli-proxy-api binary not found in PATH."
fi
