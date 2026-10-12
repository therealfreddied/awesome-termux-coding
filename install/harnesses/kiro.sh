#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Kiro / Kilo Code CLI 1-Shot Native Termux Installer
# Repository: https://github.com/therealfreddied/awesome-termux-coding
# Platform: Android / Termux aarch64 (Native Bionic / musl loader)
# Upstream: @kilocode/cli-linux-arm64-musl (official ARM64 musl binary)
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
  echo "Error: Kiro / Kilo CLI requires aarch64 (64-bit ARM). Detected: $ARCH" >&2
  exit 1
fi

OPT_DIR="$PREFIX/opt/kilo"
MUSL_LIB="$PREFIX/lib/musl"
LOADER="$MUSL_LIB/ld-musl-aarch64.so.1"

# 1. Existing Installation Detection (Repair / Delete / Exit)
if command -v kiro >/dev/null 2>&1 || command -v kilo >/dev/null 2>&1 || [ -d "$OPT_DIR" ]; then
  echo ""
  warn "Kiro / Kilo CLI is already installed on this device!"
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
      log "Uninstalling Kiro / Kilo CLI..."
      rm -rf "$OPT_DIR"
      rm -f "$PREFIX/bin/kiro" "$PREFIX/bin/kilo" "$PREFIX/bin/kilocode"
      npm uninstall -g @kilocode/cli @kilocode/cli-linux-arm64-musl >/dev/null 2>&1 || true
      ok "Kiro / Kilo CLI has been completely removed."
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
command -v tar >/dev/null 2>&1 || DEPS="$DEPS tar"
command -v gzip >/dev/null 2>&1 || DEPS="$DEPS gzip"
command -v jq >/dev/null 2>&1 || DEPS="$DEPS jq"
command -v patchelf >/dev/null 2>&1 || DEPS="$DEPS patchelf"

if [ -n "$DEPS" ]; then
  pkg update -y >/dev/null 2>&1 || true
  pkg install -y $DEPS >/dev/null 2>&1 || pkg install -y $DEPS
fi

# 3. Ensure Alpine Musl Runtime & C++ Libraries
if [ ! -f "$LOADER" ] || [ ! -f "$MUSL_LIB/libstdc++.so.6" ]; then
  log "Setting up lightweight musl runtime in $MUSL_LIB..."
  mkdir -p "$MUSL_LIB"
  TMP_MUSL="$(mktemp -d)"
  ALPINE="https://dl-cdn.alpinelinux.org/alpine/latest-stable/main/aarch64"
  MUSL_APK="$(curl -fsSL "$ALPINE/" | sed -n 's/.*href="\(musl-[0-9][^"]*\.apk\)".*/\1/p' | head -1)"
  CPP_APK="$(curl -fsSL "$ALPINE/" | sed -n 's/.*href="\(libstdc++-[0-9][^"]*\.apk\)".*/\1/p' | head -1)"
  GCC_APK="$(curl -fsSL "$ALPINE/" | sed -n 's/.*href="\(libgcc-[0-9][^"]*\.apk\)".*/\1/p' | head -1)"

  [ -n "$MUSL_APK" ] && curl -fsSL -o "$TMP_MUSL/musl.apk" "$ALPINE/$MUSL_APK" && tar xzf "$TMP_MUSL/musl.apk" -C "$TMP_MUSL" 2>/dev/null || true
  [ -n "$CPP_APK" ] && curl -fsSL -o "$TMP_MUSL/cpp.apk" "$ALPINE/$CPP_APK" && tar xzf "$TMP_MUSL/cpp.apk" -C "$TMP_MUSL" 2>/dev/null || true
  [ -n "$GCC_APK" ] && curl -fsSL -o "$TMP_MUSL/gcc.apk" "$ALPINE/$GCC_APK" && tar xzf "$TMP_MUSL/gcc.apk" -C "$TMP_MUSL" 2>/dev/null || true

  [ -f "$TMP_MUSL/lib/ld-musl-aarch64.so.1" ] && install -m 755 "$TMP_MUSL/lib/ld-musl-aarch64.so.1" "$LOADER"
  [ -f "$TMP_MUSL/usr/lib/libstdc++.so.6" ] && cp -P "$TMP_MUSL"/usr/lib/libstdc++.so* "$MUSL_LIB/"
  [ -f "$TMP_MUSL/usr/lib/libgcc_s.so.1" ] && install -m 755 "$TMP_MUSL/usr/lib/libgcc_s.so.1" "$MUSL_LIB/libgcc_s.so.1"
  rm -rf "$TMP_MUSL"
fi

# 4. Resolve and Fetch Official Musl Binary Package
PKG="@kilocode/cli-linux-arm64-musl"
log "Resolving latest $PKG..."
META="$(curl -fsSL "https://registry.npmjs.org/${PKG//\//%2f}/latest")"
VERSION="$(printf '%s' "$META" | jq -r '.version')"
TARBALL="$(printf '%s' "$META" | jq -r '.dist.tarball')"

log "Downloading official precompiled musl package (v$VERSION)..."
TMP_DIR="$(mktemp -d "$PREFIX/tmp/kilo-install.XXXXXX")"
curl -fSL --retry 3 -o "$TMP_DIR/pkg.tgz" "$TARBALL"

mkdir -p "$OPT_DIR"
tar xzf "$TMP_DIR/pkg.tgz" -C "$OPT_DIR" --strip-components=1
rm -rf "$TMP_DIR"

# 5. Patch ELF interpreter and RPATH
KILO_BIN="$OPT_DIR/bin/kilo"
if [ -f "$KILO_BIN" ]; then
  log "Patching binary with musl interpreter and rpath..."
  patchelf --set-rpath "$MUSL_LIB" --set-interpreter "$LOADER" "$KILO_BIN"
  chmod 755 "$KILO_BIN"
fi

# 6. Create Wrappers for kiro, kilo, kilocode
log "Configuring launchers in $PREFIX/bin..."
rm -f "$PREFIX/bin/kilo" "$PREFIX/bin/kiro" "$PREFIX/bin/kilocode"
cat <<'EOF' > "$PREFIX/bin/kilo"
#!/data/data/com.termux/files/usr/bin/bash
export SSL_CERT_FILE="${SSL_CERT_FILE:-$PREFIX/etc/tls/cert.pem}"
exec env -u LD_PRELOAD "$PREFIX/opt/kilo/bin/kilo" "$@"
EOF
chmod 755 "$PREFIX/bin/kilo"
ln -sf "$PREFIX/bin/kilo" "$PREFIX/bin/kiro"
ln -sf "$PREFIX/bin/kilo" "$PREFIX/bin/kilocode"

# 7. Verification
if command -v kiro >/dev/null 2>&1 || command -v kilo >/dev/null 2>&1; then
  ok "Kiro / Kilo CLI installed and verified!"
  echo ""
  echo "--------------------------------------------------------"
  echo "Run with:"
  echo "  kiro"
  echo "  or"
  echo "  kilo"
  echo ""
  echo "Installed version:"
  kilo --version 2>/dev/null || kiro --version 2>/dev/null || true
  echo "--------------------------------------------------------"
else
  warn "Binary not found in PATH ($PREFIX/bin)."
fi
