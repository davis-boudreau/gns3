#!/bin/bash

# --- 1. Environment & Software Rendering Forces ---
# These flags tell the underlying Mesa drivers to use the CPU (llvmpipe)
export LIBGL_ALWAYS_SOFTWARE=1
export GALLIUM_DRIVER=llvmpipe

# --- 2. Handle Environment Defaults ---
ACCESS_MODE=${ACCESS_MODE:-standalone}
BROWSER_MODE=${BROWSER_MODE:-kiosk} 
SCREEN_WIDTH=${SCREEN_WIDTH:-1366}
SCREEN_HEIGHT=${SCREEN_HEIGHT:-768}
SCREEN_DEPTH=${SCREEN_DEPTH:-24}
KIOSK_URL=${KIOSK_URL:-https://www.bing.com/maps}
VNC_PASSWORD=${VNC_PASSWORD:-password}
NOVNC_ENABLE=${NOVNC_ENABLE:-true}
IDLE_TIMEOUT_SECONDS=${IDLE_TIMEOUT_SECONDS:-0} # 0 = disabled

# --- 3. Resource Safety Check ---
# Check if Shared Memory is sufficient for WebGL/Chromium
SHM_SIZE=$(df -m /dev/shm | awk 'NR==2 {print $2}')
echo "LOG: Detected Shared Memory: ${SHM_SIZE}MB"
if [ "$SHM_SIZE" -lt 1000 ]; then
    echo "WARNING: Shared Memory is low (<1GB). WebGL sites like Bing Maps may crash."
    echo "Recommendation: Run container with --shm-size=2gb"
fi

# --- 4. Cleanup & System Services ---
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1
rm -rf /tmp/chromium-profile/*
# Ensure D-Bus is running (needed for Chromium/Chrome sandbox/features)
service dbus start > /dev/null 2>&1

# --- 5. VNC Security & noVNC UI Mapping ---
PASS_PARAM=""
if [ "$ACCESS_MODE" = "gns3" ]; then
    VNC_AUTH_FLAGS="-SecurityTypes None"
    echo "LOG: Mode GNS3 - No Password"
else
    mkdir -p /home/app/.vnc
    echo "$VNC_PASSWORD" | vncpasswd -f > /home/app/.vnc/passwd
    chown -R app:app /home/app/.vnc
    chmod 600 /home/app/.vnc/passwd
    VNC_AUTH_FLAGS="-rfbauth /home/app/.vnc/passwd"
    PASS_PARAM="&password=${VNC_PASSWORD}"
fi

# Link noVNC interface based on mode
# kiosk -> vnc_lite (clean) | full -> vnc (sidebar/clipboard)
if [ "$BROWSER_MODE" = "kiosk" ]; then
    VNC_FILE="vnc_lite.html"
else
    VNC_FILE="vnc.html"
fi
rm -f /usr/share/novnc/index.html
ln -s "/usr/share/novnc/${VNC_FILE}" /usr/share/novnc/index.html

# --- 6. Start VNC Server ---
sudo -u app Xvnc :1 \
    -rfbport 5900 \
    -geometry "${SCREEN_WIDTH}x${SCREEN_HEIGHT}" \
    -depth "$SCREEN_DEPTH" \
    $VNC_AUTH_FLAGS \
    -ac > /tmp/xvnc.log 2>&1 &

sleep 2
# Disable screen blanking
sudo -u app xset -display :1 s off
sudo -u app xset -display :1 -dpms

# --- 7. Start noVNC Proxy ---
if [ "$NOVNC_ENABLE" = "true" ]; then
    websockify --web /usr/share/novnc/ 8080 localhost:5900 > /tmp/novnc.log 2>&1 &
    echo "--------------------------------------------------------"
    echo "READY: http://<container_ip>:8080/index.html?autoconnect=1${PASS_PARAM}"
    echo "--------------------------------------------------------"
fi

# --- 8. Start Window Manager ---
sudo -u app fluxbox > /tmp/fluxbox.log 2>&1 &

# --- 9. Chromium & WebGL Configuration ---
# Spoofing Windows 11 / Chrome 122 to bypass Linux-WebGL blocks
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"

CHROME_ARGS="--no-first-run \
--no-default-browser-check \
--user-data-dir=/tmp/chromium-profile \
--no-sandbox \
--test-type \
--disable-dev-shm-usage \
--ignore-gpu-blocklist \
--enable-webgl \
--enable-webgl2 \
--use-gl=angle \
--use-angle=swiftshader \
--override-use-software-gl-for-webgl \
--user-agent=\"$USER_AGENT\""

if [ "$BROWSER_MODE" = "kiosk" ]; then
    CHROME_ARGS="$CHROME_ARGS --kiosk"
else
    CHROME_ARGS="$CHROME_ARGS --start-maximized"
fi

# --- 10. Background Watchdogs ---

# Idle Timeout Watchdog (Kiosk Only)
if [ "$BROWSER_MODE" = "kiosk" ] && [ "$IDLE_TIMEOUT_SECONDS" -gt 0 ]; then
    (
        while true; do
            sleep 10
            # xprintidle returns milliseconds
            IDLE_MS=$(sudo -u app xprintidle -display :1 2>/dev/null || echo 0)
            IDLE_SEC=$((IDLE_MS / 1000))
            
            if [ "$IDLE_SEC" -ge "$IDLE_TIMEOUT_SECONDS" ]; then
                echo "LOG: Idle limit reached. Resetting session..."
                pkill -u app chromium
                sleep 5
            fi
        done
    ) &
fi

# Chromium Auto-Restart Loop
(
    while true; do
        echo "LOG: Launching Chromium..."
        sudo -u app /usr/bin/chromium $CHROME_ARGS "$KIOSK_URL" > /tmp/chromium.log 2>&1
        echo "LOG: Chromium exited. Respawning..."
        sleep 3
    done
) &

tail -f /tmp/chromium.log