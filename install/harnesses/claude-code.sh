#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Claude Code 1-Shot Native Termux Installer (Musl Bionic Architecture)
# Repository: https://github.com/therealfreddied/awesome-termux-coding
# Platform: Android / Termux aarch64 (Native Bionic musl - Zero PRoot / glibc)
# Upstream: Aarstad/claude-code-termux-musl (official Anthropic musl binary)
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
  echo "Error: Claude Code requires aarch64 (64-bit ARM). Detected: $ARCH" >&2
  exit 1
fi

BUILD_DIR="$PREFIX/tmp/claude-musl-build"

# 1. Existing Installation Detection (Repair / Delete / Exit)
if command -v claude >/dev/null 2>&1 || command -v claude-musl >/dev/null 2>&1; then
  echo ""
  warn "Claude Code is already installed on this device!"
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
      log "Uninstalling Claude Code..."
      npm uninstall -g @anthropic-ai/claude-code >/dev/null 2>&1 || true
      rm -f "$PREFIX/bin/claude" "$PREFIX/bin/claude-musl" "$PREFIX/bin/claude-musl-update"
      rm -rf "$PREFIX/libexec/claude-musl" "$BUILD_DIR"
      ok "Claude Code has been completely removed."
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
command -v git >/dev/null 2>&1 || DEPS="$DEPS git"
command -v tar >/dev/null 2>&1 || DEPS="$DEPS tar"
command -v gzip >/dev/null 2>&1 || DEPS="$DEPS gzip"
command -v patchelf >/dev/null 2>&1 || DEPS="$DEPS patchelf"

if [ -n "$DEPS" ]; then
  pkg update -y >/dev/null 2>&1 || true
  pkg install -y $DEPS >/dev/null 2>&1 || pkg install -y $DEPS
fi

# Ensure JS runtime or CC exists for the native DNS proxy
if ! command -v node >/dev/null 2>&1 && ! command -v clang >/dev/null 2>&1 && ! command -v bun >/dev/null 2>&1; then
  log "Installing nodejs-lts for proxy runtime..."
  pkg install -y nodejs-lts >/dev/null 2>&1 || pkg install -y nodejs-lts
fi

# Clean up broken npm global install if present
npm uninstall -g @anthropic-ai/claude-code >/dev/null 2>&1 || true
rm -f "$PREFIX/bin/claude"

# 3. Fetch Aarstad musl engine
log "Fetching Aarstad musl Bionic installer..."
mkdir -p "$BUILD_DIR"
if [ -d "$BUILD_DIR/.git" ]; then
  git -C "$BUILD_DIR" pull --ff-only >/dev/null 2>&1 || true
else
  rm -rf "$BUILD_DIR"
  git clone --depth 1 https://github.com/Aarstad/claude-code-termux-musl.git "$BUILD_DIR" >/dev/null 2>&1
fi

# 4. Run installer with promotion to 'claude'
log "Installing official Anthropic musl binary (~723KB musl loader)..."
cd "$BUILD_DIR"
bash ./install.sh --promote >/dev/null 2>&1 || bash ./install.sh --promote

# 5. Verification
if command -v claude >/dev/null 2>&1 || command -v claude-musl >/dev/null 2>&1; then
  ok "Claude Code installed and verified!"
  echo ""
  echo "--------------------------------------------------------"
  echo "Run Claude Code with:"
  echo "  claude"
  echo ""
  echo "Installed version:"
  claude --version 2>/dev/null || claude-musl --version 2>/dev/null || true
  echo ""
  echo "To update anytime:"
  echo "  claude-musl-update"
  echo "--------------------------------------------------------"
else
  warn "claude binary was not found in PATH ($PREFIX/bin)."
fi
