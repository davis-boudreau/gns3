FROM dpage/pgadmin4:latest

USER root

RUN apk add --no-cache \
    bash \
    chromium \
    fluxbox \
    tigervnc \
    novnc \
    websockify \
    dbus \
    dbus-x11 \
    xset \
    xsetroot \
    xprintidle \
    xauth \
    sudo \
    procps \
    netcat-openbsd \
    ca-certificates \
    sed \
    python3 \
    mesa-gles

RUN adduser -D -u 1000 -s /bin/bash app && \
    mkdir -p /home/app/.fluxbox /tmp/chromium-profile /var/run/dbus && \
    chown -R app:app /home/app /tmp/chromium-profile /var/run/dbus

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN sed -i 's/\r$//' /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh

ENV DISPLAY=:1
ENV HOME=/home/app
ENV PGADMIN_LISTEN_PORT=5050
ENV PGADMIN_LISTEN_ADDRESS=0.0.0.0
ENV PGADMIN_CONFIG_SERVER_MODE=False

EXPOSE 5900 8080 5050

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
