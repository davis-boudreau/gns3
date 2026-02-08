FROM alpine:3.20

RUN apk add --no-cache \
    chromium \
    fluxbox \
    tigervnc \
    novnc \
    websockify \
    dbus \
    dbus-x11 \
    sudo \
    xset \
    xsetroot \
    xprintidle \
    mesa-gles \
    bash \
    sed \
    python3

RUN adduser -D -u 1000 app && \
    mkdir -p /home/app/.fluxbox && \
    chown -R app:app /home/app

RUN mkdir -p /var/run/dbus /tmp/chromium-profile && \
    chown -R app:app /var/run/dbus /tmp/chromium-profile

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN sed -i 's/\r$//' /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh

ENV DISPLAY=:1
ENV HOME=/home/app

EXPOSE 5900 8080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]