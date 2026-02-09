#!/bin/bash

# --- 1. Rendering Engine ---
export LIBGL_ALWAYS_SOFTWARE=1
export GALLIUM_DRIVER=llvmpipe

# --- 2. Environment Mapping ---
# These variables now strictly follow your chromium.env
ACCESS_MODE=${ACCESS_MODE:-standalone}
BROWSER_MODE=${BROWSER_MODE:-full}
SCREEN_WIDTH=${SCREEN_WIDTH:-1920}
SCREEN_HEIGHT=${SCREEN_HEIGHT:-1080}
SCREEN_DEPTH=${SCREEN_DEPTH:-24}
TARGET_URL=${DEFAULT_URL:-https://www.google.com}
VNC_PASSWORD=${VNC_PASSWORD:-mylabpass}
NOVNC_ENABLE=${NOVNC_ENABLE:-true}

# --- 3. System Cleanup ---
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1
rm -rf /tmp/chromium-profile/*
service dbus start > /dev/null 2>&1

# --- 4. VNC Security ---
if [ "$ACCESS_MODE" = "gns3" ]; then
    VNC_AUTH_FLAGS="-SecurityTypes None"
else
    mkdir -p /home/app/.vnc
    echo "$VNC_PASSWORD" | vncpasswd -f > /home/app/.vnc/passwd
    chmod 600 /home/app/.vnc/passwd
    chown -R app:app /home/app/.vnc
    VNC_AUTH_FLAGS="-rfbauth /home/app/.vnc/passwd"
fi

# --- 5. Start Display & Desktop ---
sudo -u app Xvnc :1 -rfbport 5900 -geometry "${SCREEN_WIDTH}x${SCREEN_HEIGHT}" -depth "$SCREEN_DEPTH" $VNC_AUTH_FLAGS -ac > /tmp/xvnc.log 2>&1 &
sleep 2

[ "$NOVNC_ENABLE" = "true" ] && websockify --web /usr/share/novnc/ 8080 localhost:5900 > /tmp/novnc.log 2>&1 &
sudo -u app fluxbox > /tmp/fluxbox.log 2>&1 &

# --- 6. Chromium Array (Fixes the "http://(windows" error) ---
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"

CHROME_ARGS=(
    --no-sandbox
    --test-type
    --user-data-dir=/tmp/chromium-profile
    --disable-dev-shm-usage
    --ignore-gpu-blocklist
    --enable-webgl
    --enable-webgl2
    --use-gl=angle
    --use-angle=swiftshader
    --override-use-software-gl-for-webgl
    --user-agent="$USER_AGENT"
)

# Apply Browser Mode
if [ "$BROWSER_MODE" = "kiosk" ]; then
    CHROME_ARGS+=("--kiosk")
else
    CHROME_ARGS+=("--start-maximized")
fi

# --- 7. Execution Loop ---
(
    while true; do
        echo "LOG: Launching Chromium to $TARGET_URL"
        # Using "${CHROME_ARGS[@]}" ensures the User-Agent spaces don't break the command
        sudo -u app /usr/bin/chromium "${CHROME_ARGS[@]}" "$TARGET_URL" > /tmp/chromium.log 2>&1
        sleep 3
    done
) &

tail -f /tmp/chromium.log