#!/usr/bin/env bash
set -Eeuo pipefail

# ------------------------------------------------------------------------------
# Alpine Chromium Kiosk Entrypoint (Xvfb + Fluxbox + x11vnc + optional noVNC)
# - Uses su-exec to run GUI apps as non-root "app"
# - Runs Xvfb + Fluxbox
# - Runs Chromium under a watchdog (auto-restarts on crash/exit)
# - Enforces an idle timeout that HARD-RESETS Chromium (kills it) after N seconds
#   so it always returns to KIOSK_URL via watchdog restart
# - Starts x11vnc (:5900) + optional noVNC (:6080)
#
# Logs:
#   /tmp/chromium.log
#   /tmp/fluxbox.log
#   /tmp/x11vnc.log
# ------------------------------------------------------------------------------

# -----------------------------
# Defaults / Environment
# -----------------------------
DISPLAY="${DISPLAY:-:99}"
SCREEN_WIDTH="${SCREEN_WIDTH:-1366}"
SCREEN_HEIGHT="${SCREEN_HEIGHT:-768}"
SCREEN_DEPTH="${SCREEN_DEPTH:-24}"

TZ="${TZ:-UTC}"
VNC_PASSWORD="${VNC_PASSWORD:-changeme}"
NOVNC_ENABLE="${NOVNC_ENABLE:-true}"
KIOSK_URL="${KIOSK_URL:-https://www.wikipedia.org}"

CHROME_RESTART_DELAY_SECONDS="${CHROME_RESTART_DELAY_SECONDS:-2}"

IDLE_TIMEOUT_SECONDS="${IDLE_TIMEOUT_SECONDS:-300}"               # 5 minutes
IDLE_CHECK_SECONDS="${IDLE_CHECK_SECONDS:-5}"                     # poll interval
IDLE_RESET_COOLDOWN_SECONDS="${IDLE_RESET_COOLDOWN_SECONDS:-60}"  # anti-spam + settle

# -----------------------------
# Paths
# -----------------------------
XSOCK="/tmp/.X11-unix/X${DISPLAY#:}"
XLOCK="/tmp/.X${DISPLAY#:}-lock"

SESSION_SOCK="/tmp/dbus-session.sock"
SESSION_PIDFILE="/tmp/dbus-session.pid"
SESSION_LOG="/tmp/dbus-session.log"

CHROME_LOG="/tmp/chromium.log"
FLUX_LOG="/tmp/fluxbox.log"
VNC_LOG="/tmp/x11vnc.log"

# -----------------------------
# PIDs
# -----------------------------
XVFB_PID=""
FLUX_PID=""
CHROME_PID=""
VNC_PID=""
WEBSOCKIFY_PID=""
DBUS_SESSION_PID=""
CHROME_WATCHDOG_PID=""
IDLE_MONITOR_PID=""

log() { echo "[entrypoint] $*"; }

terminate() {
  log "Shutting down…"

  # Stop background supervisors first
  for pid in "${IDLE_MONITOR_PID}" "${CHROME_WATCHDOG_PID}"; do
    if [[ -n "${pid}" ]] && kill -0 "${pid}" 2>/dev/null; then
      kill -TERM "${pid}" 2>/dev/null || true
    fi
  done

  # Stop the rest
  for pid in "${WEBSOCKIFY_PID}" "${VNC_PID}" "${CHROME_PID}" "${FLUX_PID}" "${XVFB_PID}" "${DBUS_SESSION_PID}"; do
    if [[ -n "${pid}" ]] && kill -0 "${pid}" 2>/dev/null; then
      kill -TERM "${pid}" 2>/dev/null || true
    fi
  done

  wait 2>/dev/null || true
}
trap terminate INT TERM EXIT

# ------------------------------------------------------------------------------
# Ensure required dirs / perms
# ------------------------------------------------------------------------------
mkdir -p /tmp/.X11-unix /run/dbus || true
mkdir -p /home/app/.config/chromium /home/app/.fluxbox || true
chown -R app:app /home/app || true

# Best-effort system bus (not required)
dbus-daemon --system --fork >/dev/null 2>&1 || true

# ------------------------------------------------------------------------------
# Start Xvfb
# ------------------------------------------------------------------------------
pkill -f "Xvfb ${DISPLAY}" >/dev/null 2>&1 || true
rm -f "${XLOCK}" "${XSOCK}" >/dev/null 2>&1 || true

log "Starting Xvfb on ${DISPLAY} ${SCREEN_WIDTH}x${SCREEN_HEIGHT}x${SCREEN_DEPTH}"
Xvfb "${DISPLAY}" -screen 0 "${SCREEN_WIDTH}x${SCREEN_HEIGHT}x${SCREEN_DEPTH}" -nolisten tcp &
XVFB_PID=$!

for _ in $(seq 1 80); do
  [[ -S "${XSOCK}" ]] && break
  sleep 0.1
done
if [[ ! -S "${XSOCK}" ]]; then
  log "ERROR: X socket not found at ${XSOCK}"
  exit 1
fi

# ------------------------------------------------------------------------------
# Start private DBus SESSION bus
# ------------------------------------------------------------------------------
SESSION_BUS_ADDR="unix:path=${SESSION_SOCK}"
rm -f "${SESSION_SOCK}" "${SESSION_PIDFILE}" >/dev/null 2>&1 || true

log "Starting DBus session bus at ${SESSION_BUS_ADDR}"
dbus-daemon --session \
  --address="${SESSION_BUS_ADDR}" \
  --fork \
  --print-pid \
  --pidfile="${SESSION_PIDFILE}" \
  >"${SESSION_LOG}" 2>&1 || true

DBUS_SESSION_PID="$(cat "${SESSION_PIDFILE}" 2>/dev/null || true)"

for _ in $(seq 1 50); do
  [[ -S "${SESSION_SOCK}" ]] && break
  sleep 0.1
done

export DBUS_SESSION_BUS_ADDRESS="${SESSION_BUS_ADDR}"
unset DBUS_SYSTEM_BUS_ADDRESS || true

# ------------------------------------------------------------------------------
# Seed minimal fluxbox config (quiet startup)
# ------------------------------------------------------------------------------
if [[ ! -f /home/app/.fluxbox/init ]]; then
  mkdir -p /home/app/.fluxbox
  cat > /home/app/.fluxbox/init <<'EOF'
session.screen0.toolbar.visible:     false
session.screen0.slit.autoHide:      true
session.menuSearch:                 true
EOF
  touch /home/app/.fluxbox/apps /home/app/.fluxbox/slitlist
  chown -R app:app /home/app/.fluxbox
fi

# ------------------------------------------------------------------------------
# Start Fluxbox (as app) -> log to file
# ------------------------------------------------------------------------------
log "Starting fluxbox"
: > "${FLUX_LOG}" || true
su-exec app:app env DISPLAY="${DISPLAY}" DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS}" \
  fluxbox >>"${FLUX_LOG}" 2>&1 &
FLUX_PID=$!

# ------------------------------------------------------------------------------
# Chromium profile isolation
# ------------------------------------------------------------------------------
PROFILE_DIR="/tmp/chromium-profile"
rm -rf "${PROFILE_DIR}" >/dev/null 2>&1 || true
mkdir -p "${PROFILE_DIR}"
chown -R app:app "${PROFILE_DIR}"
rm -f "${PROFILE_DIR}/SingletonLock" "${PROFILE_DIR}/SingletonCookie" "${PROFILE_DIR}/SingletonSocket" 2>/dev/null || true

# ------------------------------------------------------------------------------
# Chromium flags (container-safe)
# ------------------------------------------------------------------------------
CHROME_FLAGS=(
  --kiosk
  --no-first-run
  --no-default-browser-check
  --disable-translate
  --disable-features=TranslateUI,Vulkan

  # Container stability
  --no-sandbox
  --disable-setuid-sandbox
  --disable-dev-shm-usage
  --password-store=basic

  # Rendering stability in containers (Xvfb has no GPU)
  --disable-gpu
  --disable-vulkan
  --use-gl=swiftshader
  --ignore-gpu-blocklist

  # Profile isolation
  --user-data-dir="${PROFILE_DIR}"

  # Reduce crash plumbing noise
  --disable-breakpad
  --disable-crash-reporter

  --start-maximized
  --incognito

  # Reduce "restore crash" behaviour
  --disable-session-crashed-bubble
  --disable-infobars
)

# ------------------------------------------------------------------------------
# Hard reset: kill Chromium so watchdog restarts to KIOSK_URL
# ------------------------------------------------------------------------------
hard_reset_chromium() {
  log "Idle reset: hard resetting Chromium (terminate -> kill if needed)"

  # Graceful first
  pkill -TERM -x chromium >/dev/null 2>&1 || true
  pkill -TERM -x chromium-browser >/dev/null 2>&1 || true

  sleep 1

  # Force if still alive
  pkill -KILL -x chromium >/dev/null 2>&1 || true
  pkill -KILL -x chromium-browser >/dev/null 2>&1 || true
}

# ------------------------------------------------------------------------------
# Chromium watchdog (auto-restart)
# ------------------------------------------------------------------------------
start_chromium_watchdog() {
  trap 'exit 0' TERM INT
  local delay="${CHROME_RESTART_DELAY_SECONDS}"

  : > "${CHROME_LOG}" || true

  while true; do
    log "Launching Chromium (watchdog active)"

    # Kill any stray chromium (safety)
    pkill -x chromium >/dev/null 2>&1 || true
    pkill -x chromium-browser >/dev/null 2>&1 || true

    su-exec app:app env \
      DISPLAY="${DISPLAY}" \
      DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS}" \
      chromium "${CHROME_FLAGS[@]}" "${KIOSK_URL}" \
      >>"${CHROME_LOG}" 2>&1 &
    CHROME_PID=$!

    wait "${CHROME_PID}" || true
    log "Chromium exited (PID ${CHROME_PID}). Restarting in ${delay}s…"
    sleep "${delay}"
  done
}

# ------------------------------------------------------------------------------
# Idle monitor (hard reset on idle) - QUIET cooldown (no spam)
# ------------------------------------------------------------------------------
start_idle_monitor() {
  trap 'exit 0' TERM INT
  local timeout_ms=$(( IDLE_TIMEOUT_SECONDS * 1000 ))
  local check="${IDLE_CHECK_SECONDS}"
  local last_reset=0

  command -v xprintidle >/dev/null 2>&1 || { log "xprintidle not found; idle monitor disabled"; return; }

  while true; do
    local idle_ms now
    idle_ms="$(DISPLAY="${DISPLAY}" xprintidle 2>/dev/null || echo 0)"

    if [[ "${idle_ms}" =~ ^[0-9]+$ ]] && (( idle_ms >= timeout_ms )); then
      now="$(date +%s 2>/dev/null || echo 0)"

      if (( now - last_reset >= IDLE_RESET_COOLDOWN_SECONDS )); then
        last_reset="${now}"
        log "Idle timeout reached (${IDLE_TIMEOUT_SECONDS}s). Returning to ${KIOSK_URL} (hard reset)"
        hard_reset_chromium

        # Quiet period so we don't spam logs while user remains idle
        sleep "${IDLE_RESET_COOLDOWN_SECONDS}"
        continue
      fi
      # No logging on cooldown skips (prevents spam)
    fi

    sleep "${check}"
  done
}

# Start watchdog + idle monitor
log "Starting Chromium watchdog"
start_chromium_watchdog &
CHROME_WATCHDOG_PID=$!

log "Starting idle monitor (timeout: ${IDLE_TIMEOUT_SECONDS}s)"
start_idle_monitor &
IDLE_MONITOR_PID=$!

# ------------------------------------------------------------------------------
# x11vnc
# ------------------------------------------------------------------------------
: > "${VNC_LOG}" || true
if [[ -n "${VNC_PASSWORD}" && "${VNC_PASSWORD}" != "none" ]]; then
  log "Starting x11vnc on 0.0.0.0:5900 with password"
  x11vnc -display "${DISPLAY}" -rfbport 5900 -forever -shared -passwd "${VNC_PASSWORD}" -quiet \
    >>"${VNC_LOG}" 2>&1 &
  VNC_PID=$!
else
  log "Starting x11vnc on 0.0.0.0:5900 WITHOUT password (NOT RECOMMENDED)"
  x11vnc -display "${DISPLAY}" -rfbport 5900 -forever -shared -nopw -quiet \
    >>"${VNC_LOG}" 2>&1 &
  VNC_PID=$!
fi

# ------------------------------------------------------------------------------
# noVNC (optional)
# ------------------------------------------------------------------------------
novnc_enabled="$(printf '%s' "${NOVNC_ENABLE}" | tr '[:upper:]' '[:lower:]')"
if [[ "${novnc_enabled}" == "true" ]]; then
  NOVNC_WEB="/usr/share/novnc"
  [[ -d "${NOVNC_WEB}" ]] || NOVNC_WEB="/usr/share/webapps/novnc"

  if [[ -d "${NOVNC_WEB}" ]]; then
    log "Starting noVNC on http://0.0.0.0:6080 (proxy to :5900) using ${NOVNC_WEB}"
    websockify --web "${NOVNC_WEB}" 0.0.0.0:6080 127.0.0.1:5900 &
    WEBSOCKIFY_PID=$!
  else
    log "noVNC not found (checked /usr/share/novnc and /usr/share/webapps/novnc), skipping"
  fi
fi

log "Kiosk is running."
log "  VNC:   localhost:5900"
log "  noVNC: http://localhost:6080"
log "  Chromium log: ${CHROME_LOG}"
log "  Fluxbox log:  ${FLUX_LOG}"
log "  x11vnc log:   ${VNC_LOG}"

# Keep container alive while VNC runs
wait "${VNC_PID}"
