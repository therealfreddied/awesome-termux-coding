#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Kiro CLI (Amazon Q Developer / CodeWhisperer) 1-Shot Native Termux Installer
# Repository: https://github.com/therealfreddied/awesome-termux-coding
# Platform: Android / Termux aarch64 (Native Static Binary - Zero PRoot / glibc)
# Upstream: Amazon AWS / Kiro (desktop-release.q.us-east-1.amazonaws.com)
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
  echo "Error: Kiro CLI requires aarch64 (64-bit ARM). Detected: $ARCH" >&2
  exit 1
fi

DEST_DIR="$PREFIX/opt/kiro-cli"

# 1. Existing Installation Detection (Repair / Delete / Exit)
if command -v kiro-cli >/dev/null 2>&1 || [ -d "$DEST_DIR" ]; then
  echo ""
  warn "Kiro CLI is already installed on this device!"
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
      log "Uninstalling Kiro CLI..."
      rm -rf "$DEST_DIR"
      rm -f "$PREFIX/bin/kiro" "$PREFIX/bin/kiro-cli" "$PREFIX/bin/kiro-cli-chat" "$PREFIX/bin/kiro-cli-term" "$PREFIX/bin/q" "$PREFIX/bin/qchat"
      ok "Kiro CLI has been completely removed."
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
command -v unzip >/dev/null 2>&1 || DEPS="$DEPS unzip"

if [ -n "$DEPS" ]; then
  pkg update -y >/dev/null 2>&1 || true
  pkg install -y $DEPS >/dev/null 2>&1 || pkg install -y $DEPS
fi

# 3. Download Official AWS Static Aarch64 Build
TMP_DIR="$PREFIX/tmp/kiro-cli-install"
mkdir -p "$TMP_DIR"
cd "$TMP_DIR"

URL="https://desktop-release.q.us-east-1.amazonaws.com/latest/kirocli-aarch64-linux-musl.zip"
log "Downloading official AWS Kiro CLI (aarch64 static binaries)..."
curl -fsSL -L "$URL" -o "kirocli.zip"

log "Extracting into $DEST_DIR..."
mkdir -p "$DEST_DIR"
unzip -q -o "kirocli.zip" -d "$TMP_DIR"
cp -rf "$TMP_DIR/kirocli/"* "$DEST_DIR/"

chmod +x "$DEST_DIR/bin/"* 2>/dev/null || true
if command -v termux-fix-shebang >/dev/null 2>&1; then
  termux-fix-shebang "$DEST_DIR/bin/"* 2>/dev/null || true
fi

# 4. Link binaries to $PREFIX/bin
log "Linking binaries to $PREFIX/bin..."
mkdir -p "$PREFIX/bin"
ln -sf "$DEST_DIR/bin/kiro-cli" "$PREFIX/bin/kiro-cli"
ln -sf "$DEST_DIR/bin/kiro-cli" "$PREFIX/bin/kiro"
ln -sf "$DEST_DIR/bin/kiro-cli-chat" "$PREFIX/bin/kiro-cli-chat"
ln -sf "$DEST_DIR/bin/kiro-cli-term" "$PREFIX/bin/kiro-cli-term"
[ -f "$DEST_DIR/bin/q" ] && ln -sf "$DEST_DIR/bin/q" "$PREFIX/bin/q"
[ -f "$DEST_DIR/bin/qchat" ] && ln -sf "$DEST_DIR/bin/qchat" "$PREFIX/bin/qchat"

rm -rf "$TMP_DIR"

# 5. Verification
if command -v kiro-cli >/dev/null 2>&1 || command -v kiro >/dev/null 2>&1; then
  ok "Kiro CLI installed and verified!"
  echo ""
  echo "--------------------------------------------------------"
  echo "Run Kiro CLI with:"
  echo "  kiro"
  echo "  or"
  echo "  kiro-cli"
  echo "  kiro-cli chat"
  echo ""
  echo "Installed version:"
  kiro-cli --version 2>/dev/null || true
  echo "--------------------------------------------------------"
else
  warn "kiro binary not found on PATH ($PREFIX/bin)."
fi
