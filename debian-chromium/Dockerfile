FROM debian:bookworm-slim

# Install dependencies
# procps provides 'pkill', mesa-utils provides 'glxinfo' for debugging
RUN apt-get update && apt-get install -y \
    chromium \
    fluxbox \
    tigervnc-standalone-server \
    novnc \
    websockify \
    dbus-x11 \
    sudo \
    x11-xserver-utils \
    xprintidle \
    libgl1-mesa-dri \
    libglapi-mesa \
    libgles2-mesa \
    procps \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Setup user and directories
RUN useradd -m -u 1000 app && \
    mkdir -p /home/app/.fluxbox /tmp/chromium-profile && \
    chown -R app:app /home/app /tmp/chromium-profile

# Setup D-Bus
RUN mkdir -p /var/run/dbus && chown -R app:app /var/run/dbus

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENV DISPLAY=:1
ENV HOME=/home/app

EXPOSE 5900 8080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]