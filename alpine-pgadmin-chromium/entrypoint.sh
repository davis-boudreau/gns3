#!/bin/bash
set -euo pipefail

ACCESS_MODE=${ACCESS_MODE:-standalone}
BROWSER_MODE=${BROWSER_MODE:-full}
SCREEN_WIDTH=${SCREEN_WIDTH:-1920}
SCREEN_HEIGHT=${SCREEN_HEIGHT:-1080}
SCREEN_DEPTH=${SCREEN_DEPTH:-24}
VNC_PASSWORD=${VNC_PASSWORD:-mylabpass}
NOVNC_ENABLE=${NOVNC_ENABLE:-true}
IDLE_TIMEOUT_SECONDS=${IDLE_TIMEOUT_SECONDS:-0}

PGADMIN_DEFAULT_EMAIL=${PGADMIN_DEFAULT_EMAIL:-admin@example.com}
PGADMIN_DEFAULT_PASSWORD=${PGADMIN_DEFAULT_PASSWORD:-admin}
PGADMIN_LISTEN_ADDRESS=${PGADMIN_LISTEN_ADDRESS:-0.0.0.0}
PGADMIN_LISTEN_PORT=${PGADMIN_LISTEN_PORT:-5050}
PGADMIN_SERVER_NAME=${PGADMIN_SERVER_NAME:-Lab PostgreSQL}
PGADMIN_SERVER_GROUP=${PGADMIN_SERVER_GROUP:-Servers}
PGADMIN_SERVER_HOST=${PGADMIN_SERVER_HOST:-postgres}
PGADMIN_SERVER_PORT=${PGADMIN_SERVER_PORT:-5432}
PGADMIN_SERVER_MAINTENANCE_DB=${PGADMIN_SERVER_MAINTENANCE_DB:-postgres}
PGADMIN_SERVER_USERNAME=${PGADMIN_SERVER_USERNAME:-postgres}
PGADMIN_SERVER_PASSWORD=${PGADMIN_SERVER_PASSWORD:-postgres}
PGADMIN_SERVER_SSLMODE=${PGADMIN_SERVER_SSLMODE:-prefer}
PGADMIN_AUTO_SETUP=${PGADMIN_AUTO_SETUP:-true}

DEFAULT_URL=${DEFAULT_URL:-http://127.0.0.1:${PGADMIN_LISTEN_PORT}}

export DISPLAY HOME PGADMIN_DEFAULT_EMAIL PGADMIN_DEFAULT_PASSWORD
export PGADMIN_LISTEN_ADDRESS PGADMIN_LISTEN_PORT
export PGADMIN_CONFIG_SERVER_MODE=${PGADMIN_CONFIG_SERVER_MODE:-False}
export PGADMIN_CONFIG_MASTER_PASSWORD_REQUIRED=${PGADMIN_CONFIG_MASTER_PASSWORD_REQUIRED:-False}

rm -f /tmp/.X1-lock /tmp/.X11-unix/X1
rm -f /tmp/chromium-profile/SingletonLock

mkdir -p /tmp/.X11-unix /var/run/dbus /pgadmin4 /var/lib/pgadmin
dbus-daemon --system --fork 2>/dev/null || true

if [ "$PGADMIN_AUTO_SETUP" = "true" ]; then
    USER_STORAGE_DIR="/var/lib/pgadmin/storage/${PGADMIN_DEFAULT_EMAIL}"
    mkdir -p "$USER_STORAGE_DIR"

    cat > /pgadmin4/servers.json <<EOF
{
  "Servers": {
    "1": {
      "Name": "${PGADMIN_SERVER_NAME}",
      "Group": "${PGADMIN_SERVER_GROUP}",
      "Host": "${PGADMIN_SERVER_HOST}",
      "Port": ${PGADMIN_SERVER_PORT},
      "MaintenanceDB": "${PGADMIN_SERVER_MAINTENANCE_DB}",
      "Username": "${PGADMIN_SERVER_USERNAME}",
      "SSLMode": "${PGADMIN_SERVER_SSLMODE}",
      "PassFile": "${USER_STORAGE_DIR}/pgpass"
    }
  }
}
EOF

    cat > "${USER_STORAGE_DIR}/pgpass" <<EOF
${PGADMIN_SERVER_HOST}:${PGADMIN_SERVER_PORT}:${PGADMIN_SERVER_MAINTENANCE_DB}:${PGADMIN_SERVER_USERNAME}:${PGADMIN_SERVER_PASSWORD}
EOF
    chmod 600 "${USER_STORAGE_DIR}/pgpass"
fi

PASS_PARAM=""
if [ "$ACCESS_MODE" = "gns3" ]; then
    VNC_AUTH_FLAGS="-SecurityTypes None"
else
    mkdir -p /home/app/.vnc
    echo "$VNC_PASSWORD" | vncpasswd -f > /home/app/.vnc/passwd
    chown -R app:app /home/app/.vnc
    chmod 600 /home/app/.vnc/passwd
    VNC_AUTH_FLAGS="-rfbauth /home/app/.vnc/passwd"
    PASS_PARAM="&password=${VNC_PASSWORD}"
fi

if [ "$BROWSER_MODE" = "kiosk" ]; then
    VNC_FILE="vnc_lite.html"
else
    VNC_FILE="vnc.html"
fi

rm -f /usr/share/novnc/index.html
ln -s "/usr/share/novnc/${VNC_FILE}" /usr/share/novnc/index.html

/entrypoint.sh > /tmp/pgadmin.log 2>&1 &
PGADMIN_PID=$!

for _ in $(seq 1 60); do
    if nc -z 127.0.0.1 "${PGADMIN_LISTEN_PORT}" >/dev/null 2>&1; then
        break
    fi
    sleep 1
done

sudo -u app Xvnc :1 \
    -rfbport 5900 \
    -geometry "${SCREEN_WIDTH}x${SCREEN_HEIGHT}" \
    -depth "${SCREEN_DEPTH}" \
    ${VNC_AUTH_FLAGS} \
    -ac > /tmp/xvnc.log 2>&1 &

sleep 2

sudo -u app xset -display :1 s off
sudo -u app xset -display :1 -dpms
sudo -u app fluxbox > /tmp/fluxbox.log 2>&1 &

if [ "$NOVNC_ENABLE" = "true" ]; then
    websockify --web /usr/share/novnc/ 8080 localhost:5900 > /tmp/novnc.log 2>&1 &
    echo "--------------------------------------------------------"
    echo "noVNC URL: http://<container_ip>:8080/index.html?autoconnect=1${PASS_PARAM}"
    echo "pgAdmin URL: http://<container_ip>:${PGADMIN_LISTEN_PORT}"
    echo "--------------------------------------------------------"
fi

CHROMIUM_BIN="/usr/bin/chromium"
if [ ! -x "$CHROMIUM_BIN" ]; then
    CHROMIUM_BIN="/usr/bin/chromium-browser"
fi

CHROME_ARGS="--no-first-run \
--no-default-browser-check \
--user-data-dir=/tmp/chromium-profile \
--no-sandbox \
--test-type \
--disable-dev-shm-usage \
--ignore-gpu-blocklist \
--enable-webgl \
--enable-webgl2 \
--enable-es3-apis \
--use-gl=angle \
--use-angle=swiftshader \
--override-use-software-gl-for-webgl \
--disable-features=Vulkan,VulkanFromANGLE,Libvulkan"

if [ "$BROWSER_MODE" = "kiosk" ]; then
    CHROME_ARGS="$CHROME_ARGS --kiosk"
else
    CHROME_ARGS="$CHROME_ARGS --start-maximized"
fi

if [ "$BROWSER_MODE" = "kiosk" ] && [ "$IDLE_TIMEOUT_SECONDS" -gt 0 ]; then
    (
        while true; do
            sleep 10
            IDLE_MS=$(sudo -u app xprintidle -display :1 2>/dev/null || echo 0)
            IDLE_SEC=$((IDLE_MS / 1000))
            if [ "$IDLE_SEC" -ge "$IDLE_TIMEOUT_SECONDS" ]; then
                pkill -u app chromium || true
                pkill -u app chromium-browser || true
                sleep 5
            fi
        done
    ) &
fi

(
    while true; do
        sudo -u app "$CHROMIUM_BIN" $CHROME_ARGS "$DEFAULT_URL" > /tmp/chromium.log 2>&1
        sleep 3
    done
) &
CHROMIUM_LOOP_PID=$!

wait -n "$PGADMIN_PID" "$CHROMIUM_LOOP_PID"
