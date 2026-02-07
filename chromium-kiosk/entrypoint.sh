#!/usr/bin/env bash
set -Eeuo pipefail

# ------------------------------------------------------------------------------
# Alpine Chromium Kiosk Entrypoint (Xvnc + Fluxbox + Chromium + optional noVNC)
#
# Architecture:
#   Xvnc (TigerVNC) = X server + VNC server in one
#   Fluxbox         = window manager
#   Chromium        = kiosk app with watchdog + idle hard reset
#   noVNC           = optional web access (standalone only)
#
# Logs:
#   /tmp/chromium.log
#   /tmp/fluxbox.log
#   /tmp/xvnc.log
#   /tmp/dbus-session.log
# ------------------------------------------------------------------------------

# -----------------------------
# Defaults / Environment
# -----------------------------
ACCESS_MODE="$(printf '%s' "${ACCESS_MODE:-gns3}" | tr '[:upper:]' '[:lower:]')"

DISPLAY_NUMBER="${DISPLAY_NUMBER:-1}"
DISPLAY=":${DISPLAY_NUMBER}"

SCREEN_WIDTH="${SCREEN_WIDTH:-1366}"
SCREEN_HEIGHT="${SCREEN_HEIGHT:-768}"
SCREEN_DEPTH="${SCREEN_DEPTH:-24}"

TZ="${TZ:-UTC}"
KIOSK_URL="${KIOSK_URL:-https://www.google.com}"

VNC_PASSWORD="${VNC_PASSWORD:-changeme}"
NOVNC_ENABLE="$(printf '%s' "${NOVNC_ENABLE:-false}" | tr '[:upper:]' '[:lower:]')"

CHROME_RESTART_DELAY_SECONDS="${CHROME_RESTART_DELAY_SECONDS:-2}"

IDLE_TIMEOUT_SECONDS="${IDLE_TIMEOUT_SECONDS:-300}"
IDLE_CHECK_SECONDS="${IDLE_CHECK_SECONDS:-5}"
IDLE_RESET_COOLDOWN_SECONDS="${IDLE_RESET_COOLDOWN_SECONDS:-60}"

# -----------------------------
# Paths
# -----------------------------
SESSION_SOCK="/tmp/dbus-session.sock"
SESSION_PIDFILE="/tmp/dbus-session.pid"
DBUS_LOG="/tmp/dbus-session.log"

CHROME_LOG="/tmp/chromium.log"
FLUX_LOG="/tmp/fluxbox.log"
XVNC_LOG="/tmp/xvnc.log"

VNC_PASS_FILE="/tmp/vncpasswd"

# -----------------------------
# PIDs
# -----------------------------
XVNC_PID=""
FLUX_PID=""
CHROME_PID=""
WEBSOCKIFY_PID=""
DBUS_SESSION_PID=""
CHROME_WATCHDOG_PID=""
IDLE_MONITOR_PID=""

log() { echo "[entrypoint] $*"; }

terminate() {
  log "Shutting down…"

  for pid in "${IDLE_MONITOR_PID}" "${CHROME_WATCHDOG_PID}" "${WEBSOCKIFY_PID}" "${CHROME_PID}" "${FLUX_PID}" "${XVNC_PID}" "${DBUS_SESSION_PID}"; do
    if [[ -n "${pid}" ]] && kill -0 "${pid}" 2>/dev/null; then
      kill -TERM "${pid}" 2>/dev/null || true
    fi
  done

  wait 2>/dev/null || true
}
trap terminate INT TERM EXIT

# ----------------------------------------------------------------------
# Ensure dirs / perms
# ----------------------------------------------------------------------
mkdir -p /home/app/.config/chromium /home/app/.fluxbox || true
chown -R app:app /home/app || true

# ----------------------------------------------------------------------
# DBus session bus (robust + wait for socket)
# ----------------------------------------------------------------------
rm -f "${SESSION_SOCK}" "${SESSION_PIDFILE}" >/dev/null 2>&1 || true
: > "${DBUS_LOG}" || true

SESSION_BUS_ADDR="unix:path=${SESSION_SOCK}"
log "Starting DBus session bus at ${SESSION_BUS_ADDR}"

# Try with --pidfile (some builds support it). If it fails to create a socket,
# we fall back to a simpler invocation.
dbus-daemon --session \
  --address="${SESSION_BUS_ADDR}" \
  --fork \
  --pidfile="${SESSION_PIDFILE}" \
  >>"${DBUS_LOG}" 2>&1 || true

DBUS_SESSION_PID="$(cat "${SESSION_PIDFILE}" 2>/dev/null || true)"
export DBUS_SESSION_BUS_ADDRESS="${SESSION_BUS_ADDR}"
unset DBUS_SYSTEM_BUS_ADDRESS || true

# Wait for the socket so Chromium doesn't race it
for _ in $(seq 1 50); do
  [[ -S "${SESSION_SOCK}" ]] && break
  sleep 0.1
done

# Fallback: if socket wasn't created, retry without pidfile
if [[ ! -S "${SESSION_SOCK}" ]]; then
  log "WARNING: DBus session socket not created (retrying without --pidfile)."
  rm -f "${SESSION_SOCK}" "${SESSION_PIDFILE}" >/dev/null 2>&1 || true

  dbus-daemon --session \
    --address="${SESSION_BUS_ADDR}" \
    --fork \
    >>"${DBUS_LOG}" 2>&1 || true

  # Wait again
  for _ in $(seq 1 50); do
    [[ -S "${SESSION_SOCK}" ]] && break
    sleep 0.1
  done
fi

if [[ ! -S "${SESSION_SOCK}" ]]; then
  log "WARNING: DBus session socket still not present at ${SESSION_SOCK}."
  log "DBus log (last 80 lines):"
  tail -n 80 "${DBUS_LOG}" || true
else
  log "DBus session socket ready: ${SESSION_SOCK}"
fi

# ----------------------------------------------------------------------
# Quiet Fluxbox startup (seed minimal config)
# ----------------------------------------------------------------------
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

# ----------------------------------------------------------------------
# Start Xvnc (TigerVNC) - replaces Xvfb + x11vnc
# ----------------------------------------------------------------------
: > "${XVNC_LOG}" || true

VNC_SECURITY_ARGS=()
if [[ "${ACCESS_MODE}" == "standalone" ]]; then
  # Standalone: protect VNC with password unless "none"
  if [[ -n "${VNC_PASSWORD}" && "${VNC_PASSWORD}" != "none" ]]; then
    printf '%s\n' "${VNC_PASSWORD}" | vncpasswd -f > "${VNC_PASS_FILE}"
    chmod 600 "${VNC_PASS_FILE}"
    VNC_SECURITY_ARGS=( -rfbauth "${VNC_PASS_FILE}" -SecurityTypes VncAuth )
    log "Xvnc: VNC authentication enabled (standalone)"
  else
    VNC_SECURITY_ARGS=( -SecurityTypes None )
    log "Xvnc: NO VNC authentication (standalone, not recommended)"
  fi
else
  # GNS3: let GNS3 manage console access; keep container auth off
  VNC_SECURITY_ARGS=( -SecurityTypes None )
  log "Xvnc: GNS3 mode (no container-level VNC auth)"
fi

log "Starting Xvnc on ${DISPLAY} (port 5900) ${SCREEN_WIDTH}x${SCREEN_HEIGHT}x${SCREEN_DEPTH}"
Xvnc "${DISPLAY}" \
  -rfbport 5900 \
  -geometry "${SCREEN_WIDTH}x${SCREEN_HEIGHT}" \
  -depth "${SCREEN_DEPTH}" \
  "${VNC_SECURITY_ARGS[@]}" \
  >>"${XVNC_LOG}" 2>&1 &
XVNC_PID=$!

# Wait for X to be ready
for _ in $(seq 1 80); do
  xdpyinfo -display "${DISPLAY}" >/dev/null 2>&1 && break || true
  sleep 0.1
done

# ----------------------------------------------------------------------
# Start Fluxbox on Xvnc display
# ----------------------------------------------------------------------
log "Starting fluxbox"
: > "${FLUX_LOG}" || true
su-exec app:app env DISPLAY="${DISPLAY}" DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS}" \
  fluxbox >>"${FLUX_LOG}" 2>&1 &
FLUX_PID=$!

# ----------------------------------------------------------------------
# Chromium flags (container-safe + virtual display stability)
# ----------------------------------------------------------------------
PROFILE_DIR="/tmp/chromium-profile"
rm -rf "${PROFILE_DIR}" >/dev/null 2>&1 || true
mkdir -p "${PROFILE_DIR}"
chown -R app:app "${PROFILE_DIR}"

CHROME_FLAGS=(
  --kiosk
  --no-first-run
  --no-default-browser-check
  --disable-translate

  # Avoid Vulkan paths
  --disable-features=TranslateUI,Vulkan,UseSkiaRenderer

  # Container stability
  --no-sandbox
  --disable-setuid-sandbox
  --disable-dev-shm-usage
  --password-store=basic

  # Rendering stability on virtual X server (no GPU)
  --disable-gpu
  --disable-vulkan
  --use-gl=swiftshader
  --use-angle=swiftshader
  --ozone-platform=x11
  --ignore-gpu-blocklist

  --user-data-dir="${PROFILE_DIR}"

  # Reduce crash UX noise
  --disable-breakpad
  --disable-crash-reporter
  --disable-session-crashed-bubble
  --disable-infobars

  --start-maximized
  --incognito
)

hard_reset_chromium() {
  log "Idle reset: hard resetting Chromium (terminate -> kill if needed)"
  pkill -TERM -x chromium >/dev/null 2>&1 || true
  pkill -TERM -x chromium-browser >/dev/null 2>&1 || true
  sleep 1
  pkill -KILL -x chromium >/dev/null 2>&1 || true
  pkill -KILL -x chromium-browser >/dev/null 2>&1 || true
}

start_chromium_watchdog() {
  trap 'exit 0' TERM INT
  : > "${CHROME_LOG}" || true

  while true; do
    log "Launching Chromium (watchdog active)"
    pkill -x chromium >/dev/null 2>&1 || true
    pkill -x chromium-browser >/dev/null 2>&1 || true

    su-exec app:app env \
      DISPLAY="${DISPLAY}" \
      DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS}" \
      chromium "${CHROME_FLAGS[@]}" "${KIOSK_URL}" \
      >>"${CHROME_LOG}" 2>&1 &

    CHROME_PID=$!
    wait "${CHROME_PID}" || true

    # Helpful hint (keeps debugging local, not forever spammy)
    log "Chromium exited (PID ${CHROME_PID}). Last 40 lines of ${CHROME_LOG}:"
    tail -n 40 "${CHROME_LOG}" || true

    log "Restarting Chromium in ${CHROME_RESTART_DELAY_SECONDS}s…"
    sleep "${CHROME_RESTART_DELAY_SECONDS}"
  done
}

start_idle_monitor() {
  trap 'exit 0' TERM INT
  local timeout_ms=$(( IDLE_TIMEOUT_SECONDS * 1000 ))
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
        sleep "${IDLE_RESET_COOLDOWN_SECONDS}"
        continue
      fi
    fi

    sleep "${IDLE_CHECK_SECONDS}"
  done
}

log "Starting Chromium watchdog"
start_chromium_watchdog &
CHROME_WATCHDOG_PID=$!

log "Starting idle monitor (timeout: ${IDLE_TIMEOUT_SECONDS}s)"
start_idle_monitor &
IDLE_MONITOR_PID=$!

# ----------------------------------------------------------------------
# noVNC (standalone only)
# ----------------------------------------------------------------------
if [[ "${ACCESS_MODE}" == "standalone" && "${NOVNC_ENABLE}" == "true" ]]; then
  NOVNC_WEB="/usr/share/novnc"
  [[ -d "${NOVNC_WEB}" ]] || NOVNC_WEB="/usr/share/webapps/novnc"

  if [[ -d "${NOVNC_WEB}" ]]; then
    log "Starting noVNC on http://0.0.0.0:6080 (proxy to :5900) using ${NOVNC_WEB}"
    websockify --web "${NOVNC_WEB}" 0.0.0.0:6080 127.0.0.1:5900 &
    WEBSOCKIFY_PID=$!
  else
    log "noVNC web root not found; skipping noVNC"
  fi
else
  log "noVNC disabled (ACCESS_MODE=${ACCESS_MODE}, NOVNC_ENABLE=${NOVNC_ENABLE})"
fi

log "Kiosk is running."
log "  VNC:   localhost:5900 (DISPLAY ${DISPLAY})"
log "  noVNC: http://localhost:6080 (standalone only)"
log "  Chromium log: ${CHROME_LOG}"
log "  Fluxbox log:  ${FLUX_LOG}"
log "  Xvnc log:     ${XVNC_LOG}"
log "  DBus log:     ${DBUS_LOG}"

# Keep container alive: if Xvnc dies, kiosk is dead.
wait "${XVNC_PID}"
