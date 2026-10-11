#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# 9router 1-Shot Native Termux Installer
# Repository: https://github.com/therealfreddied/awesome-termux-coding
# Platform: Android / Termux aarch64 (Native Bionic - No PRoot required)
# Purpose: Ultra-lightweight AI proxy router designed for low-memory environments
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
command -v curl >/dev/null 2>&1 || DEPS="$DEPS curl"
command -v tar >/dev/null 2>&1 || DEPS="$DEPS tar"

if [ -n "$DEPS" ]; then
  pkg update -y >/dev/null 2>&1 || true
  pkg install -y $DEPS
fi

VERSION="0.5.99"
DEST_DIR="$PREFIX/lib/9router"
TMP_DIR="$PREFIX/tmp/9router-install"

mkdir -p "$TMP_DIR" "$DEST_DIR"
log "Downloading 9router@$VERSION npm tarball..."
curl -fsSL "https://registry.npmjs.org/9router/-/9router-${VERSION}.tgz" -o "$TMP_DIR/9router.tgz"

log "Extracting to $DEST_DIR..."
tar -xzf "$TMP_DIR/9router.tgz" --strip-components=1 -C "$DEST_DIR"

# Ensure machine ID exists without relying on systemd/D-Bus
mkdir -p "$HOME/.9router"
if [ ! -f "$HOME/.9router/machine-id" ]; then
  if [ -r /proc/sys/kernel/random/boot_id ]; then
    cat /proc/sys/kernel/random/boot_id > "$HOME/.9router/machine-id"
  else
    head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$HOME/.9router/machine-id"
  fi
  chmod 600 "$HOME/.9router/machine-id" 2>/dev/null || true
fi

# Patch client.js for Android/Termux if node-machine-id is called
node - "$DEST_DIR" <<'EOF'
const fs = require('fs');
const path = require('path');
const p = path.join(process.argv[2], 'src', 'cli', 'api', 'client.js');
if (fs.existsSync(p)) {
  let src = fs.readFileSync(p, 'utf8');
  src = src.replace(/const\s*\{\s*machineIdSync\s*\}\s*=\s*require\(["']node-machine-id["']\);?\r?\n?/, '');
  fs.writeFileSync(p, src);
}
EOF

# Install launcher
cat <<'EOF' > "$PREFIX/bin/9router"
#!/data/data/com.termux/files/usr/bin/bash
exec node "$PREFIX/lib/9router/cli.js" "$@"
EOF
chmod +x "$PREFIX/bin/9router"

rm -rf "$TMP_DIR"

if command -v 9router >/dev/null 2>&1; then
  ok "9router installed successfully!"
  echo ""
  echo "--------------------------------------------------------"
  echo "Launch with:"
  echo "  9router start"
  echo ""
  echo "Ultra-low RAM consumption, ideal for Termux backgrounding!"
  echo "--------------------------------------------------------"
else
  warn "9router binary not found in PATH."
fi
