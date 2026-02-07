FROM alpine:3.20

ARG NOVNC_VERSION=v1.5.0
ARG WEBSOCKIFY_PY_VERSION=0.12.0

ENV DISPLAY=:99 \
    SCREEN_WIDTH=1366 \
    SCREEN_HEIGHT=768 \
    SCREEN_DEPTH=24 \
    TZ=UTC \
    NOVNC_ENABLE=true

RUN printf '%s\n' \
  "https://dl-cdn.alpinelinux.org/alpine/v3.20/main" \
  "https://dl-cdn.alpinelinux.org/alpine/v3.20/community" \
  > /etc/apk/repositories

# Core stack + tools (tar/gzip important)
RUN apk add --no-cache \
      bash su-exec coreutils procps \
      chromium \
      xvfb \
      x11vnc \
      fluxbox \
      dbus \
      nss \
      ca-certificates \
      bash \
      tini \
      curl \
      tar \
      gzip \
      python3 \
      py3-pip \
      fontconfig \
      ttf-dejavu \
      xdotool \
      xprintidle


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
    echo "Downloading noVNC ${NOVNC_VERSION} from GitHub..."; \
    curl -fL --retry 3 --retry-delay 2 -v \
      -o /tmp/novnc.tar.gz \
      "https://github.com/novnc/noVNC/archive/refs/tags/${NOVNC_VERSION}.tar.gz"; \
    echo "Extracting..."; \
    tar -xzf /tmp/novnc.tar.gz --strip-components=1 -C /usr/share/novnc; \
    rm -f /tmp/novnc.tar.gz; \
  fi; \
  \
  echo "=== Locating noVNC web root ==="; \
  # Alpine package layouts vary. Support common paths.
  if [ -d /usr/share/novnc ]; then \
    NOVNC_ROOT=/usr/share/novnc; \
  elif [ -d /usr/share/webapps/novnc ]; then \
    NOVNC_ROOT=/usr/share/webapps/novnc; \
  else \
    echo "ERROR: noVNC web directory not found."; \
    echo "Contents of /usr/share:"; ls -la /usr/share || true; \
    echo "Contents of /usr/share/webapps:"; ls -la /usr/share/webapps || true; \
    exit 1; \
  fi; \
  echo "Using NOVNC_ROOT=$NOVNC_ROOT"; \
  # Make sure index exists
  ln -sf "$NOVNC_ROOT/vnc_lite.html" "$NOVNC_ROOT/index.html" || true; \
  test -f "$NOVNC_ROOT/index.html"; \
  \
  echo "=== websockify binary/path ==="; \
  command -v websockify || python3 -c "import websockify; print('websockify import OK')" || exit 1

# Non-root user with a real shell + writable home
RUN addgroup -S app \
  && adduser -S -G app -h /home/app -s /bin/sh app \
  && mkdir -p /home/app/.config/chromium /home/app/.fluxbox /var/run/dbus \
  && chown -R app:app /home/app /var/run/dbus \
  && chmod 0755 /home/app

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# Normalize entrypoint: CRLF + UTF-8 BOM safe
RUN set -eux; \
    chmod 0755 /usr/local/bin/entrypoint.sh; \
    sed -i 's/\r$//' /usr/local/bin/entrypoint.sh; \
    bom="$(od -An -tx1 -N3 /usr/local/bin/entrypoint.sh | tr -d ' \n')"; \
    if [ "$bom" = "efbbbf" ]; then \
      echo "Stripping UTF-8 BOM from entrypoint.sh"; \
      tail -c +4 /usr/local/bin/entrypoint.sh > /tmp/entrypoint.sh; \
      mv /tmp/entrypoint.sh /usr/local/bin/entrypoint.sh; \
      chmod 0755 /usr/local/bin/entrypoint.sh; \
    fi; \
    [ "$(head -c 2 /usr/local/bin/entrypoint.sh)" = "#!" ]

EXPOSE 5900 6080

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/usr/local/bin/entrypoint.sh"]
