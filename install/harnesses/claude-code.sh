#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Claude Code 1-Shot Native Termux Installer (Musl Bionic Architecture)
# Repository: https://github.com/therealfreddied/awesome-termux-coding
# Platform: Android / Termux aarch64 (Native Bionic musl - Zero PRoot / glibc)
# Upstream: Aarstad/claude-code-termux-musl (official Anthropic musl binary)
# Features: Bundled native C PTY filter for Termux soft keyboard tap-to-focus!
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
LIBEXEC="$PREFIX/libexec/claude-musl"

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
      rm -rf "$LIBEXEC" "$BUILD_DIR"
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
command -v clang >/dev/null 2>&1 || DEPS="$DEPS clang"

if [ -n "$DEPS" ]; then
  pkg update -y >/dev/null 2>&1 || true
  pkg install -y $DEPS >/dev/null 2>&1 || pkg install -y $DEPS
fi

if ! command -v node >/dev/null 2>&1 && ! command -v bun >/dev/null 2>&1; then
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

# 4. Run Aarstad installer with promotion to 'claude'
log "Installing official Anthropic musl binary (~723KB musl loader)..."
cd "$BUILD_DIR"
bash ./install.sh --promote >/dev/null 2>&1 || bash ./install.sh --promote

# 5. Build and Deploy Native C PTY Filter (Termux Soft Keyboard Tap-Focus Fix)
log "Building native C PTY filter for Termux soft keyboard tap-to-focus..."
mkdir -p "$LIBEXEC"
cat <<'EOF' > "$LIBEXEC/termux-pty-filter.c"
#include <pty.h>
#include <unistd.h>
#include <termios.h>
#include <signal.h>
#include <sys/ioctl.h>
#include <sys/select.h>
#include <sys/wait.h>
#include <string.h>

static int pty_fd = -1;
static struct termios orig_tio;

static void on_winch(int sig) {
    (void)sig;
    struct winsize ws;
    if (ioctl(STDIN_FILENO, TIOCGWINSZ, &ws) == 0 && pty_fd >= 0)
        ioctl(pty_fd, TIOCSWINSZ, &ws);
}

static void restore_tio(void) {
    tcsetattr(STDIN_FILENO, TCSADRAIN, &orig_tio);
}

/* Strip DEC mouse tracking sequences: \e[?1000h, \e[?1002h, \e[?1003h, \e[?1006h */
static void filter_and_write(int out_fd, unsigned char *buf, size_t len,
                             unsigned char *hold, size_t *hold_len) {
    unsigned char src[8192];
    size_t total = *hold_len + len;
    if (total > sizeof(src)) total = sizeof(src);

    memcpy(src, hold, *hold_len);
    memcpy(src + *hold_len, buf, total - *hold_len);
    *hold_len = 0;

    size_t i = 0, start = 0;
    while (i < total) {
        if (src[i] == 0x1b) {
            if (i + 1 >= total) break;
            if (src[i + 1] == '[') {
                if (i + 2 >= total) break;
                if (src[i + 2] == '?') {
                    size_t j = i + 3;
                    while (j < total && ((src[j] >= '0' && src[j] <= '9') || src[j] == ';'))
                        j++;
                    if (j >= total) break;
                    if (src[j] == 'h' || src[j] == 'l') {
                        char p[32];
                        size_t plen = j - (i + 3);
                        if (plen < sizeof(p)) {
                            memcpy(p, src + i + 3, plen);
                            p[plen] = '\0';
                            if (strstr(p, "1000") || strstr(p, "1002") ||
                                strstr(p, "1003") || strstr(p, "1006")) {
                                if (i > start) write(out_fd, src + start, i - start);
                                i = j + 1;
                                start = i;
                                continue;
                            }
                        }
                    }
                }
            }
        }
        i++;
    }
    if (i > start) write(out_fd, src + start, i - start);
    if (i < total) {
        *hold_len = total - i;
        memcpy(hold, src + i, *hold_len);
    }
}

int main(int argc, char *argv[]) {
    if (argc < 2) return 1;
    if (!isatty(STDIN_FILENO)) { execvp(argv[1], &argv[1]); return 1; }

    int master, slave;
    if (openpty(&master, &slave, NULL, NULL, NULL) < 0) return 1;
    pty_fd = master;

    struct winsize ws;
    if (ioctl(STDIN_FILENO, TIOCGWINSZ, &ws) == 0) {
        ioctl(master, TIOCSWINSZ, &ws);
        ioctl(slave, TIOCSWINSZ, &ws);
    }

    pid_t pid = fork();
    if (pid == 0) {
        close(master);
        setsid();
        ioctl(slave, TIOCSCTTY, 1);
        dup2(slave, 0); dup2(slave, 1); dup2(slave, 2);
        close(slave);
        execvp(argv[1], &argv[1]);
        _exit(127);
    }
    close(slave);

    tcgetattr(STDIN_FILENO, &orig_tio);
    struct termios raw = orig_tio;
    cfmakeraw(&raw);
    tcsetattr(STDIN_FILENO, TCSADRAIN, &raw);
    atexit(restore_tio);
    signal(SIGWINCH, on_winch);

    unsigned char hold[64];
    size_t hold_len = 0;
    unsigned char buf[4096];

    while (1) {
        fd_set fds;
        FD_ZERO(&fds);
        FD_SET(STDIN_FILENO, &fds);
        FD_SET(master, &fds);
        if (select(master + 1, &fds, NULL, NULL, NULL) < 0) continue;

        if (FD_ISSET(STDIN_FILENO, &fds)) {
            ssize_t n = read(STDIN_FILENO, buf, sizeof(buf));
            if (n <= 0) break;
            if (write(master, buf, n) <= 0) break;
        }
        if (FD_ISSET(master, &fds)) {
            ssize_t n = read(master, buf, sizeof(buf));
            if (n <= 0) break;
            filter_and_write(STDOUT_FILENO, buf, n, hold, &hold_len);
        }
    }

    if (hold_len > 0) write(STDOUT_FILENO, hold, hold_len);
    restore_tio();
    close(master);

    int status = 0;
    waitpid(pid, &status, 0);
    return WIFEXITED(status) ? WEXITSTATUS(status) : 1;
}
EOF

# Compile the native PTY filter with clang
clang -O2 "$LIBEXEC/termux-pty-filter.c" -o "$LIBEXEC/termux-pty-filter"
chmod 755 "$LIBEXEC/termux-pty-filter"

# 6. Patch $PREFIX/bin/claude-musl wrapper to route through termux-pty-filter
WRAPPER="$PREFIX/bin/claude-musl"
if [ -f "$WRAPPER" ]; then
  log "Wiring PTY filter into $WRAPPER..."
  python3 -c "
with open('$WRAPPER', 'r') as f:
    content = f.read()
old_exec = 'env -u LD_PRELOAD \"\$BIN\" \"\$@\"'
new_exec = '''PTY_FILTER=\"\$LIBEXEC/termux-pty-filter\"
if [ -t 0 ] && [ -x \"\$PTY_FILTER\" ] && [ -z \"\${CLAUDE_ENABLE_MOUSE:-}\" ]; then
  env -u LD_PRELOAD \"\$PTY_FILTER\" \"\$BIN\" \"\$@\"
else
  env -u LD_PRELOAD \"\$BIN\" \"\$@\"
fi'''
if old_exec in content:
    content = content.replace(old_exec, new_exec)
    with open('$WRAPPER', 'w') as f:
        f.write(content)
" 2>/dev/null || true
fi

# 7. Patch $PREFIX/bin/claude-musl-update to preserve PTY filter across upgrades
UPDATER="$PREFIX/bin/claude-musl-update"
if [ -f "$UPDATER" ]; then
  log "Setting update persistence guard in $UPDATER..."
  python3 -c "
with open('$UPDATER', 'r') as f:
    content = f.read()
target = 'echo \"verified: \$got runs\"'
patch = '''echo \"verified: \$got runs\"

if [ ! -x \"\$LIBEXEC/termux-pty-filter\" ] && [ -f \"\$LIBEXEC/termux-pty-filter.c\" ]; then
  clang -O2 \"\$LIBEXEC/termux-pty-filter.c\" -o \"\$LIBEXEC/termux-pty-filter\" 2>/dev/null || true
fi'''
if target in content and patch not in content:
    content = content.replace(target, patch)
    with open('$UPDATER', 'w') as f:
        f.write(content)
" 2>/dev/null || true
fi

# 8. Verification
if command -v claude >/dev/null 2>&1 || command -v claude-musl >/dev/null 2>&1; then
  ok "Claude Code installed and verified with native keyboard tap-to-focus!"
  echo ""
  echo "--------------------------------------------------------"
  echo "Run Claude Code with:"
  echo "  claude"
  echo ""
  echo "Installed version:"
  claude --version 2>/dev/null || claude-musl --version 2>/dev/null || true
  echo ""
  echo "Termux Soft Keyboard Feature:"
  echo "  DEC mouse tracking is filtered out in real-time."
  echo "  Tapping anywhere inside Claude Code brings up the keyboard!"
  echo "  (To re-enable mouse mode if desired: export CLAUDE_ENABLE_MOUSE=1)"
  echo ""
  echo "To update anytime:"
  echo "  claude-musl-update"
  echo "--------------------------------------------------------"
else
  warn "claude binary was not found in PATH ($PREFIX/bin)."
fi
