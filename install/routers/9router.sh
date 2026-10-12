#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# 9router 1-Shot Native Termux Installer (Self-Updating Architecture)
# Repository: https://github.com/therealfreddied/awesome-termux-coding
# Platform: Android / Termux aarch64 (Native Bionic - No PRoot required)
# Purpose: Ultra-lightweight AI proxy router with permanent Termux compatibility
#          allowing seamless upstream updates via built-in updater or npm.
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
command -v git >/dev/null 2>&1 || DEPS="$DEPS git"
command -v curl >/dev/null 2>&1 || DEPS="$DEPS curl"

if [ -n "$DEPS" ]; then
  pkg update -y >/dev/null 2>&1 || true
  pkg install -y $DEPS
fi

NPM_PREFIX="$(npm config get prefix)"
if [ "$NPM_PREFIX" != "$PREFIX" ]; then
  npm config set prefix "$PREFIX"
fi

# 1. Ensure permanent persistent directory and persistent machine-id
ROUTER_HOME="$HOME/.9router"
mkdir -p "$ROUTER_HOME"

if [ ! -f "$ROUTER_HOME/machine-id" ]; then
  log "Generating persistent Android Bionic machine-id..."
  if [ -r /proc/sys/kernel/random/boot_id ]; then
    cat /proc/sys/kernel/random/boot_id > "$ROUTER_HOME/machine-id"
  else
    head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$ROUTER_HOME/machine-id"
  fi
  chmod 600 "$ROUTER_HOME/machine-id" 2>/dev/null || true
fi

# 2. Deploy permanent Node.js runtime preload shim
# This shim lives OUTSIDE npm's node_modules in ~/.9router/termux-preload.js.
# Whenever 9router starts (or updates), Node loads this shim first via NODE_OPTIONS="-r ...",
# transparently intercepting "node-machine-id" and bridging Android Bionic.
# Upstream updates will NEVER wipe or invalidate this fix!
log "Installing permanent runtime preload shim at $ROUTER_HOME/termux-preload.js..."
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

# 3. Install 9router globally via standard npm
log "Installing 9router globally via npm..."
npm install -g --omit=dev --no-audit --no-fund 9router

# 4. Patch Bionic shebangs in global install
PKG_DIR="$PREFIX/lib/node_modules/9router"
if command -v termux-fix-shebang >/dev/null 2>&1; then
  if [ -d "$PKG_DIR" ]; then
    find "$PKG_DIR" -maxdepth 3 -type f -perm /111 -exec termux-fix-shebang {} + 2>/dev/null || true
  fi
fi

# 5. Create persistent wrapper at $PREFIX/bin/9router
# Injects NODE_OPTIONS="-r $ROUTER_HOME/termux-preload.js" so all runs and sub-processes
# inherit the Android Bionic compatibility layer.
log "Configuring launcher wrapper at $PREFIX/bin/9router..."
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
  # Fallback in case npm linked directly
  exec npx 9router "$@"
fi
EOF
chmod 755 "$PREFIX/bin/9router"
termux-fix-shebang "$PREFIX/bin/9router" 2>/dev/null || true

# 6. Verification
if command -v 9router >/dev/null 2>&1; then
  ok "9router installed with Self-Updating Architecture!"
  echo ""
  echo "--------------------------------------------------------"
  echo "Run 9router with:"
  echo "  9router start"
  echo ""
  echo "Installed version:"
  9router --version 2>/dev/null || true
  echo ""
  echo "Self-Updating Guarantee:"
  echo "  You can safely update 9router anytime using:"
  echo "  - In-app Web UI / terminal update button"
  echo "  - Or manually: npm i -g 9router@latest"
  echo "  The Termux compatibility layer is isolated and persists across updates!"
  echo "--------------------------------------------------------"
else
  warn "9router binary not found on PATH ($PREFIX/bin)."
fi
