#!/bin/bash

# ==========================================================
# 1. CLEAN UP PREVIOUS SESSION LOCKS
# ==========================================================
# Remove X11 server locks to prevent "A server is already running" errors
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1

# Remove Chromium's "SingletonLock". 
# This prevents the "Profile is in use by another computer" error 
# caused by changing container IDs.
rm -f /tmp/chromium-profile/SingletonLock

# ==========================================================
# 2. START VNC SERVER
# ==========================================================
# Run Xvnc as the 'app' user to ensure display ownership matches the browser.
# -SecurityTypes None is used for ease of use in GNS3 lab environments.
sudo -u app Xvnc :1 \
    -rfbport 5900 \
    -geometry 1366x768 \
    -depth 24 \
    -SecurityTypes None \
    -ac > /tmp/xvnc.log 2>&1 &

# Brief sleep to ensure the X server is socket-ready
sleep 2

# Start D-Bus system daemon to quiet the logs
mkdir -p /var/run/dbus
dbus-daemon --system --fork 2>/dev/null

# ==========================================================
# 3. START WINDOW MANAGER
# ==========================================================
# Fluxbox handles the windowing so Chromium can run in fullscreen/kiosk mode.
sudo -u app fluxbox > /tmp/fluxbox.log 2>&1 &

# ==========================================================
# 4. START CHROMIUM
# ==========================================================
# --disable-features=Vulkan... suppresses the driver warnings you saw.
# --user-data-dir points to our persistent volume.
sudo -u app /usr/lib/chromium/chromium \
    --kiosk \
    --no-first-run \
    --no-default-browser-check \
    --user-data-dir=/tmp/chromium-profile \
    --no-sandbox \
    --disable-dev-shm-usage \
    --disable-gpu \
    --disable-software-rasterizer \
    --disable-features=Vulkan,VulkanFromANGLE,Libvulkan \
    --disable-gpu-sandbox \
    --use-gl=swiftshader \
    --incognito \
    --remote-debugging-port=9222 \
    https://www.google.com > /tmp/chromium.log 2>&1 &

# ==========================================================
# 5. KEEP CONTAINER ALIVE
# ==========================================================
# Tail the log so 'docker logs' shows browser activity
tail -f /tmp/chromium.log