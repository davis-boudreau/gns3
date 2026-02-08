#!/bin/bash

# --- 1. Handle Environment Defaults ---
ACCESS_MODE=${ACCESS_MODE:-standalone}
BROWSER_MODE=${BROWSER_MODE:-kiosk} 
SCREEN_WIDTH=${SCREEN_WIDTH:-1366}
SCREEN_HEIGHT=${SCREEN_HEIGHT:-768}
SCREEN_DEPTH=${SCREEN_DEPTH:-24}
DEFAULT_URL=${DEFAULT_URL:-https://www.google.com}
VNC_PASSWORD=${VNC_PASSWORD:-password}
NOVNC_ENABLE=${NOVNC_ENABLE:-true}
IDLE_TIMEOUT_SECONDS=${IDLE_TIMEOUT_SECONDS:-0} # 0 = disabled

# --- 2. Cleanup & D-Bus Setup ---
# Remove X11 and Chromium locks
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1
rm -f /tmp/chromium-profile/SingletonLock

# Start D-Bus system daemon
mkdir -p /var/run/dbus
dbus-daemon --system --fork 2>/dev/null

# --- 3. Configure VNC Security & noVNC URL Params ---
PASS_PARAM=""

if [ "$ACCESS_MODE" = "gns3" ]; then
    VNC_AUTH_FLAGS="-SecurityTypes None"
    echo "LOG: ACCESS_MODE is 'gns3'. Disabling VNC password."
else
    mkdir -p /home/app/.vnc
    echo "$VNC_PASSWORD" | vncpasswd -f > /home/app/.vnc/passwd
    chown -R app:app /home/app/.vnc
    chmod 600 /home/app/.vnc/passwd
    VNC_AUTH_FLAGS="-rfbauth /home/app/.vnc/passwd"
    # Prepare password parameter for the noVNC auto-login
    PASS_PARAM="&password=${VNC_PASSWORD}"
    echo "LOG: ACCESS_MODE is 'standalone'. VNC password enabled."
fi

# --- 4. Select noVNC Interface ---
# Kiosk Mode -> vnc_lite.html (Minimal)
# Full Mode  -> vnc.html (Sidebar for clipboard/keys)
if [ "$BROWSER_MODE" = "kiosk" ]; then
    VNC_FILE="vnc_lite.html"
    echo "LOG: BROWSER_MODE is 'kiosk'. UI set to vnc_lite."
else
    VNC_FILE="vnc.html"
    echo "LOG: BROWSER_MODE is 'full'. UI set to vnc."
fi

# Link the selected UI to index.html
rm -f /usr/share/novnc/index.html
ln -s "/usr/share/novnc/${VNC_FILE}" /usr/share/novnc/index.html

# --- 5. Start VNC Server ---
sudo -u app Xvnc :1 \
    -rfbport 5900 \
    -geometry "${SCREEN_WIDTH}x${SCREEN_HEIGHT}" \
    -depth "$SCREEN_DEPTH" \
    $VNC_AUTH_FLAGS \
    -ac > /tmp/xvnc.log 2>&1 &

sleep 2

# Disable screen saver and power management
sudo -u app xset -display :1 s off
sudo -u app xset -display :1 -dpms

# --- 6. Start noVNC Proxy ---
if [ "$NOVNC_ENABLE" = "true" ]; then
    websockify --web /usr/share/novnc/ 8080 localhost:5900 > /tmp/novnc.log 2>&1 &
    echo "--------------------------------------------------------"
    echo "noVNC URL: http://<container_ip>:8080/index.html?autoconnect=1${PASS_PARAM}"
    echo "--------------------------------------------------------"
fi

# --- 7. Start Window Manager ---
sudo -u app fluxbox > /tmp/fluxbox.log 2>&1 &

# --- 8. Start Chromium with Forced WebGL ---
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

# Add the mode-specific flags
if [ "$BROWSER_MODE" = "kiosk" ]; then
    CHROME_ARGS="$CHROME_ARGS --kiosk"
else
    CHROME_ARGS="$CHROME_ARGS --start-maximized"
fi

# Watchdog logic: Restart Chromium if idle (Kiosk mode only)
if [ "$BROWSER_MODE" = "kiosk" ] && [ "$IDLE_TIMEOUT_SECONDS" -gt 0 ]; then
    (
        while true; do
            sleep 10
            IDLE_MS=$(sudo -u app xprintidle -display :1 2>/dev/null || echo 0)
            IDLE_SEC=$((IDLE_MS / 1000))
            
            if [ "$IDLE_SEC" -ge "$IDLE_TIMEOUT_SECONDS" ]; then
                echo "LOG: Idle timeout reached (${IDLE_SEC}s). Resetting Chromium..."
                pkill -u app chromium
                # The browser-restart-loop below will pick it back up
                sleep 5
            fi
        done
    ) &
fi

# Browser-restart-loop: Ensure Chromium stays running
(
    while true; do
        echo "LOG: Launching Chromium..."
        sudo -u app /usr/lib/chromium/chromium $CHROME_ARGS "$DEFAULT_URL" > /tmp/chromium.log 2>&1
        echo "LOG: Chromium exited. Restarting in 3 seconds..."
        sleep 3
    done
) &

# Keep container running and stream logs
tail -f /tmp/chromium.log