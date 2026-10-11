#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Free Claude Code (FCC) 1-Shot Native Termux Installer
# Repository: https://github.com/therealfreddied/awesome-termux-coding
# Platform: Android / Termux aarch64 (Native Bionic - No PRoot required)
# Upstream: Alishahryar1/free-claude-code
# Purpose: Gives Claude Code, Codex, OpenCode & Pi access to 61 free-tier providers
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
command -v python >/dev/null 2>&1 || DEPS="$DEPS python"
command -v git >/dev/null 2>&1 || DEPS="$DEPS git"
command -v curl >/dev/null 2>&1 || DEPS="$DEPS curl"

if [ -n "$DEPS" ]; then
  pkg update -y >/dev/null 2>&1 || true
  pkg install -y $DEPS
fi

INSTALL_DIR="$HOME/.free-claude-code"
log "Installing Free Claude Code engine into $INSTALL_DIR..."

if [ -d "$INSTALL_DIR/.git" ]; then
  git -C "$INSTALL_DIR" pull --ff-only || true
else
  rm -rf "$INSTALL_DIR"
  git clone --depth 1 https://github.com/Alishahryar1/free-claude-code.git "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

log "Setting up Python virtual environment..."
python -m venv "$INSTALL_DIR/venv"
"$INSTALL_DIR/venv/bin/pip" install --upgrade pip setuptools wheel
if [ -f "$INSTALL_DIR/pyproject.toml" ]; then
  "$INSTALL_DIR/venv/bin/pip" install -e "$INSTALL_DIR" || "$INSTALL_DIR/venv/bin/pip" install -r requirements.txt 2>/dev/null || true
fi

# Create launcher
cat <<'EOF' > "$PREFIX/bin/fcc-server"
#!/data/data/com.termux/files/usr/bin/bash
INSTALL_DIR="$HOME/.free-claude-code"
if [ -f "$INSTALL_DIR/venv/bin/fcc-server" ]; then
  exec "$INSTALL_DIR/venv/bin/fcc-server" "$@"
else
  exec "$INSTALL_DIR/venv/bin/python" -m fcc "$@"
fi
EOF
chmod +x "$PREFIX/bin/fcc-server"

ok "Free Claude Code installed successfully!"
echo ""
echo "--------------------------------------------------------"
echo "Start the FCC daemon:"
echo "  fcc-server"
echo ""
echo "Access the mobile Admin UI in your browser to configure"
echo "free token models for Claude Code, Codex, or OpenCode!"
echo "--------------------------------------------------------"
