#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# 9router 1-Shot Native Termux Installer (Self-Updating Architecture)
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

ROUTER_HOME="$HOME/.9router"

# 1. Existing Installation Detection (Repair / Delete / Exit)
if command -v 9router >/dev/null 2>&1 || [ -d "$PREFIX/lib/node_modules/9router" ]; then
  echo ""
  warn "9router is already installed on this device!"
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
      log "Uninstalling 9router..."
      rm -f "$PREFIX/bin/9router"
      npm uninstall -g 9router >/dev/null 2>&1 || true
      rm -f "$ROUTER_HOME/termux-preload.js"
      ok "9router has been completely removed."
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

NPM_PREFIX="$(npm config get prefix)"
if [ "$NPM_PREFIX" != "$PREFIX" ]; then
  npm config set prefix "$PREFIX"
fi

mkdir -p "$ROUTER_HOME"

if [ ! -f "$ROUTER_HOME/machine-id" ]; then
  log "Generating persistent Android machine-id..."
  if [ -r /proc/sys/kernel/random/boot_id ]; then
    cat /proc/sys/kernel/random/boot_id > "$ROUTER_HOME/machine-id"
  else
    head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$ROUTER_HOME/machine-id"
  fi
  chmod 600 "$ROUTER_HOME/machine-id" 2>/dev/null || true
fi

# 3. Permanent Runtime Preload Shim
log "Configuring runtime preload shim at $ROUTER_HOME/termux-preload.js..."
cat <<'EOF' > "$ROUTER_HOME/termux-preload.js"
const Module = require('module');
const fs = require('fs');
const path = require('path');
const os = require('os');

const origLoad = Module._load;
Module._load = function(request, parent, isMain) {
  if (request === 'node-machine-id') {
    return {
      machineIdSync: () => {
        try {
          const idPath = path.join(process.env.HOME || os.homedir(), '.9router', 'machine-id');
          if (fs.existsSync(idPath)) {
            const id = fs.readFileSync(idPath, 'utf8').trim();
            if (id) return id;
          }
        } catch (_) {}
        return 'termux-bionic-machine-id';
      },
      machineId: async () => {
        try {
          const idPath = path.join(process.env.HOME || os.homedir(), '.9router', 'machine-id');
          if (fs.existsSync(idPath)) {
            const id = fs.readFileSync(idPath, 'utf8').trim();
            if (id) return id;
          }
        } catch (_) {}
        return 'termux-bionic-machine-id';
      }
    };
  }
  return origLoad.apply(this, arguments);
};
EOF

# 4. Clean npm install with warning suppression
log "Installing 9router globally via npm..."
rm -f "$PREFIX/bin/9router"
ALLOW_FLAG=""
if npm install --help 2>&1 | grep -q -- "--allow-scripts"; then
  ALLOW_FLAG="--allow-scripts=9router"
fi
npm install -g --omit=dev --no-audit --no-fund --loglevel=error $ALLOW_FLAG 9router >/dev/null 2>&1 || \
npm install -g --omit=dev --no-audit --no-fund --loglevel=error 9router >/dev/null 2>&1 || \
npm install -g --omit=dev --no-audit --no-fund 9router >/dev/null 2>&1

# 5. Patch shebangs
PKG_DIR="$PREFIX/lib/node_modules/9router"
if command -v termux-fix-shebang >/dev/null 2>&1; then
  if [ -d "$PKG_DIR" ]; then
    find "$PKG_DIR" -maxdepth 3 -type f -perm /111 -exec termux-fix-shebang {} + 2>/dev/null || true
  fi
fi

# 6. Configure launcher wrapper
log "Configuring launcher wrapper at $PREFIX/bin/9router..."
rm -f "$PREFIX/bin/9router"
cat <<'EOF' > "$PREFIX/bin/9router"
#!/data/data/com.termux/files/usr/bin/bash
PRELOAD="$HOME/.9router/termux-preload.js"
if [ -f "$PRELOAD" ]; then
  case "${NODE_OPTIONS:-}" in
    *"$PRELOAD"*) ;;
    *) export NODE_OPTIONS="${NODE_OPTIONS:-} -r $PRELOAD" ;;
  esac
fi
CLI_PATH="$PREFIX/lib/node_modules/9router/cli.js"
if [ -f "$CLI_PATH" ]; then
  exec node "$CLI_PATH" "$@"
else
  exec npx 9router "$@"
fi
EOF
chmod 755 "$PREFIX/bin/9router"
termux-fix-shebang "$PREFIX/bin/9router" 2>/dev/null || true

# 7. Verification
if command -v 9router >/dev/null 2>&1; then
  ok "9router installed and verified!"
  echo ""
  echo "--------------------------------------------------------"
  echo "Run 9router with:"
  echo "  9router start"
  echo ""
  echo "Installed version:"
  9router --version 2>/dev/null || true
  echo ""
  echo "Self-Updating Guarantee:"
  echo "  You can safely update 9router anytime via Web UI or npm."
  echo "--------------------------------------------------------"
else
  warn "9router binary not found on PATH ($PREFIX/bin)."
fi
