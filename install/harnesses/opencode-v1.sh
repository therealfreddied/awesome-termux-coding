#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# OpenCode v1.x (Classic) 1-Shot Native Termux Installer
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

ARCH="$(uname -m)"
if [ "$ARCH" != "aarch64" ]; then
  echo "Error: OpenCode binary requires an aarch64 (64-bit ARM) device. Detected: $ARCH" >&2
  exit 1
fi

# 1. Existing Installation Detection (Repair / Delete / Exit)
if command -v opencode >/dev/null 2>&1; then
  echo ""
  warn "OpenCode v1.x is already installed on this device!"
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
      log "Uninstalling OpenCode v1.x..."
      dpkg -r opencode >/dev/null 2>&1 || true
      rm -f "$PREFIX/bin/opencode"
      rm -rf "$PREFIX/libexec/opencode"
      ok "OpenCode v1.x has been completely removed."
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
command -v dpkg >/dev/null 2>&1 || DEPS="$DEPS dpkg"
command -v rg >/dev/null 2>&1 || DEPS="$DEPS ripgrep"

if [ -n "$DEPS" ]; then
  pkg update -y >/dev/null 2>&1 || true
  pkg install -y $DEPS >/dev/null 2>&1 || pkg install -y $DEPS
fi

TMP_DIR="$PREFIX/tmp/opencode1-install"
mkdir -p "$TMP_DIR"
cd "$TMP_DIR"

DEB_URL="https://github.com/guysoft/opencode-termux/releases/download/v0.2.0-1.3.13-bashfix8/opencode_1.3.13_aarch64.deb"
log "Downloading OpenCode v1.x deb package..."
curl -fsSL -L "$DEB_URL" -o "opencode_1.3.13_aarch64.deb"

log "Installing package via dpkg..."
dpkg -i --force-overwrite "opencode_1.3.13_aarch64.deb" >/dev/null 2>&1 || apt-get install -f -y >/dev/null 2>&1

rm -rf "$TMP_DIR"

if command -v opencode >/dev/null 2>&1; then
  ok "OpenCode v1.x installed and verified!"
  echo ""
  echo "--------------------------------------------------------"
  echo "Run OpenCode v1 with:"
  echo "  opencode"
  echo "--------------------------------------------------------"
else
  warn "opencode binary not found on PATH ($PREFIX/bin)."
fi
