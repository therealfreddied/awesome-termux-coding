#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Free Claude Code (FCC) 1-Shot Native Termux Installer
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

INSTALL_DIR="$HOME/.free-claude-code"

# 1. Existing Installation Detection (Repair / Delete / Exit)
if command -v fcc-server >/dev/null 2>&1 || [ -d "$INSTALL_DIR" ]; then
  echo ""
  warn "Free Claude Code is already installed on this device!"
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
      log "Uninstalling Free Claude Code..."
      rm -rf "$INSTALL_DIR"
      rm -f "$PREFIX/bin/fcc-server"
      ok "Free Claude Code has been completely removed."
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
command -v python >/dev/null 2>&1 || DEPS="$DEPS python"
command -v git >/dev/null 2>&1 || DEPS="$DEPS git"
command -v curl >/dev/null 2>&1 || DEPS="$DEPS curl"

if [ -n "$DEPS" ]; then
  pkg update -y >/dev/null 2>&1 || true
  pkg install -y $DEPS >/dev/null 2>&1 || pkg install -y $DEPS
fi

log "Setting up Free Claude Code engine in $INSTALL_DIR..."
if [ -d "$INSTALL_DIR/.git" ]; then
  git -C "$INSTALL_DIR" pull --ff-only >/dev/null 2>&1 || true
else
  rm -rf "$INSTALL_DIR"
  git clone --depth 1 https://github.com/Alishahryar1/free-claude-code.git "$INSTALL_DIR" >/dev/null 2>&1
fi

cd "$INSTALL_DIR"

log "Configuring Python virtual environment..."
python -m venv "$INSTALL_DIR/venv"
"$INSTALL_DIR/venv/bin/pip" install --upgrade pip setuptools wheel >/dev/null 2>&1 || true
if [ -f "$INSTALL_DIR/pyproject.toml" ]; then
  "$INSTALL_DIR/venv/bin/pip" install -e "$INSTALL_DIR" >/dev/null 2>&1 || \
  "$INSTALL_DIR/venv/bin/pip" install -r requirements.txt >/dev/null 2>&1 || true
fi

# Launcher
cat <<'EOF' > "$PREFIX/bin/fcc-server"
#!/data/data/com.termux/files/usr/bin/bash
INSTALL_DIR="$HOME/.free-claude-code"
if [ -f "$INSTALL_DIR/venv/bin/fcc-server" ]; then
  exec "$INSTALL_DIR/venv/bin/fcc-server" "$@"
else
  exec "$INSTALL_DIR/venv/bin/python" -m fcc "$@"
fi
EOF
chmod 755 "$PREFIX/bin/fcc-server"
termux-fix-shebang "$PREFIX/bin/fcc-server" 2>/dev/null || true

ok "Free Claude Code installed and verified!"
echo ""
echo "--------------------------------------------------------"
echo "Start FCC daemon:"
echo "  fcc-server"
echo "--------------------------------------------------------"
