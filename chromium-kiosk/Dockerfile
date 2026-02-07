FROM alpine:3.20

ARG NOVNC_VERSION=v1.5.0
ARG WEBSOCKIFY_PY_VERSION=0.12.0

ENV TZ=UTC

RUN printf '%s\n' \
  "https://dl-cdn.alpinelinux.org/alpine/v3.20/main" \
  "https://dl-cdn.alpinelinux.org/alpine/v3.20/community" \
  > /etc/apk/repositories

RUN apk add --no-cache \
      bash su-exec coreutils procps \
      chromium \
      fluxbox \
      dbus \
      nss \
      ca-certificates \
      tini \
      curl \
      tar \
      gzip \
      python3 \
      py3-pip \
      fontconfig \
      ttf-dejavu \
      xdotool \
      xprintidle \
      tigervnc

# Optional fonts (don’t fail build)
RUN apk add --no-cache noto-fonts || true
RUN apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/v3.20/community noto-fonts-emoji || true

# --- noVNC install (package-first, fallback to pip+github) ---
RUN set -eux; \
  echo "=== Attempt 1: Alpine packages (preferred) ==="; \
  if apk add --no-cache novnc websockify; then \
    echo "Installed novnc + websockify from Alpine."; \
  else \
    echo "Alpine novnc/websockify not available, falling back to pip + GitHub tarball."; \
    pip install --no-cache-dir "websockify==${WEBSOCKIFY_PY_VERSION}"; \
    mkdir -p /usr/share/novnc; \
    curl -fL --retry 3 --retry-delay 2 -o /tmp/novnc.tar.gz \
      "https://github.com/novnc/noVNC/archive/refs/tags/${NOVNC_VERSION}.tar.gz"; \
    tar -xzf /tmp/novnc.tar.gz --strip-components=1 -C /usr/share/novnc; \
    rm -f /tmp/novnc.tar.gz; \
  fi; \
  if [ -d /usr/share/novnc ]; then \
    ln -sf /usr/share/novnc/vnc_lite.html /usr/share/novnc/index.html || true; \
    test -f /usr/share/novnc/index.html; \
  elif [ -d /usr/share/webapps/novnc ]; then \
    ln -sf /usr/share/webapps/novnc/vnc_lite.html /usr/share/webapps/novnc/index.html || true; \
    test -f /usr/share/webapps/novnc/index.html; \
  fi

RUN addgroup -S app \
  && adduser -S -G app -h /home/app -s /bin/sh app \
  && mkdir -p /home/app/.config/chromium /home/app/.fluxbox /var/run/dbus \
  && chown -R app:app /home/app /var/run/dbus \
  && chmod 0755 /home/app

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN set -eux; \
    chmod 0755 /usr/local/bin/entrypoint.sh; \
    sed -i 's/\r$//' /usr/local/bin/entrypoint.sh; \
    bom="$(od -An -tx1 -N3 /usr/local/bin/entrypoint.sh | tr -d ' \n')"; \
    if [ "$bom" = "efbbbf" ]; then \
      tail -c +4 /usr/local/bin/entrypoint.sh > /tmp/entrypoint.sh; \
      mv /tmp/entrypoint.sh /usr/local/bin/entrypoint.sh; \
      chmod 0755 /usr/local/bin/entrypoint.sh; \
    fi; \
    [ "$(head -c 2 /usr/local/bin/entrypoint.sh)" = "#!" ]

EXPOSE 5900 6080

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/usr/local/bin/entrypoint.sh"]
