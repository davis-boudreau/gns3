FROM alpine:3.20

# 1. Added 'bash' and 'sed' to the apk add command
RUN apk add --no-cache \
    chromium \
    fluxbox \
    tigervnc \
    dbus \
    dbus-x11 \
    sudo \
    xsetroot \
    mesa-gles \
    bash \
    sed

# Create user and ensure home directory exists
RUN adduser -D -u 1000 app && \
    mkdir -p /home/app/.fluxbox && \
    chown -R app:app /home/app

# Pre-create D-Bus and Profile dirs
RUN mkdir -p /var/run/dbus /tmp/chromium-profile && \
    chown -R app:app /var/run/dbus /tmp/chromium-profile

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# 2. FIX: Convert Windows line endings (CRLF) to Linux (LF) and make executable
RUN sed -i 's/\r$//' /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh

ENV DISPLAY=:1
ENV HOME=/home/app

EXPOSE 5900

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]