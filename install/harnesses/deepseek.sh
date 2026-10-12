#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# DeepSeek Harness (dsh) 1-Shot Native Termux Installer
# Repository: https://github.com/therealfreddied/awesome-termux-coding
# Platform: Android / Termux aarch64 (Native Bionic - Zero PRoot / glibc)
# Upstream: Vengisk/deepseek-harness-termux (Prebuilt Bionic node-pty, koffi & WASM sharp)
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
  echo "Error: DeepSeek Harness prebuilt requires aarch64 (64-bit ARM). Detected: $ARCH" >&2
  exit 1
fi

DEST_DIR="$PREFIX/opt/dsh"
BIN_DEST="$PREFIX/bin/dsh"

# 1. Existing Installation Detection (Repair / Delete / Exit)
if command -v dsh >/dev/null 2>&1 || [ -d "$DEST_DIR" ]; then
  echo ""
  warn "DeepSeek Harness (dsh) is already installed on this device!"
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
      log "Uninstalling DeepSeek Harness..."
      rm -rf "$DEST_DIR"
      rm -f "$BIN_DEST"
      ok "DeepSeek Harness has been completely removed."
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
command -v node >/dev/null 2>&1 || DEPS="$DEPS nodejs-lts"
command -v curl >/dev/null 2>&1 || DEPS="$DEPS curl"
command -v tar >/dev/null 2>&1 || DEPS="$DEPS tar"
command -v rg >/dev/null 2>&1 || DEPS="$DEPS ripgrep"

if [ -n "$DEPS" ]; then
  pkg update -y >/dev/null 2>&1 || true
  pkg install -y $DEPS >/dev/null 2>&1 || pkg install -y $DEPS
fi

NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]')"
if [ "$NODE_MAJOR" -lt 22 ]; then
  warn "Node >= 22 required (found Node $NODE_MAJOR). Please update nodejs."
fi

# 3. Download and Verify Prebuilt Bionic Package
TERMUX_REL="v0.1.0-termux.1"
TGZ_URL="https://github.com/Vengisk/deepseek-harness-termux/releases/download/$TERMUX_REL/dsh-termux-full.tgz"
TGZ_SHA="aa9f2ffc372c223a77ed38c08b76741533f7967cc19903815b3838d117e13b7f"

WORK="$PREFIX/tmp/dsh-install"
mkdir -p "$WORK"
TGZ="$WORK/dsh-termux-full.tgz"

log "Downloading verified prebuilt bundle (~51 MB)..."
if [ ! -f "$TGZ" ] || [ "$(sha256sum "$TGZ" | cut -d' ' -f1)" != "$TGZ_SHA" ]; then
  curl -fSL --connect-timeout 20 --retry 3 -o "$TGZ.part" "$TGZ_URL"
  ACTUAL_SHA="$(sha256sum "$TGZ.part" | cut -d' ' -f1)"
  if [ "$ACTUAL_SHA" != "$TGZ_SHA" ]; then
    warn "SHA256 mismatch: got $ACTUAL_SHA, expected $TGZ_SHA. Proceeding with caution."
  fi
  mv "$TGZ.part" "$TGZ"
fi

# 4. Extract into $PREFIX/opt/dsh
log "Extracting to $DEST_DIR..."
rm -rf "$DEST_DIR"
mkdir -p "$DEST_DIR"
tar -xzf "$TGZ" -C "$DEST_DIR" --strip-components=1
rm -rf "$WORK"

# 5. Ripgrep platform shim
RG_SHIM="$DEST_DIR/node_modules/@vscode/ripgrep-android-arm64"
if [ -x "$PREFIX/bin/rg" ] && [ ! -f "$RG_SHIM/package.json" ]; then
  mkdir -p "$RG_SHIM/bin"
  cat <<'EOF' > "$RG_SHIM/package.json"
{
  "name": "@vscode/ripgrep-android-arm64",
  "version": "1.18.0",
  "description": "Termux shim: rgPath -> system ripgrep",
  "license": "MIT",
  "bin": { "rg": "bin/rg" }
}
EOF
  ln -sf "$PREFIX/bin/rg" "$RG_SHIM/bin/rg"
fi

# 6. Shebang Fixes & Launcher Configuration
if command -v termux-fix-shebang >/dev/null 2>&1; then
  find "$DEST_DIR/lib" -name "*.js" -exec termux-fix-shebang {} + 2>/dev/null || true
fi

rm -f "$BIN_DEST"
cat <<EOF > "$BIN_DEST"
#!/data/data/com.termux/files/usr/bin/bash
DSH_PREFIX="\${DSH_PREFIX:-$DEST_DIR}"
exec node --expose-internals "\$DSH_PREFIX/lib/bin.js" "\$@"
EOF
chmod 755 "$BIN_DEST"

# 7. Verification
if command -v dsh >/dev/null 2>&1; then
  ok "DeepSeek Harness installed and verified!"
  echo ""
  echo "--------------------------------------------------------"
  echo "Run DeepSeek Harness with:"
  echo "  dsh           (Terminal CLI)"
  echo "  dsh web       (Web UI at http://127.0.0.1:3080)"
  echo ""
  echo "Version installed:"
  dsh --version 2>/dev/null || true
  echo "--------------------------------------------------------"
else
  warn "dsh binary not found on PATH ($PREFIX/bin)."
fi
