# Chromium Kiosk Container

This repository provides a lightweight, production-ready Chromium browser running inside a Linux container with full graphical access.

The image is designed for kiosk systems, teaching labs, virtualized environments, and remote browser access where no physical display or GPU is available.

Chromium runs inside a virtual X display using Xvfb and a lightweight window manager (Fluxbox), and can be accessed through either VNC or a web browser using noVNC.

---

## What this image provides

* Chromium with full graphical interface
* Virtual display using Xvfb (no monitor or GPU required)
* Lightweight window manager (Fluxbox)
* VNC access on port **5900**
* Browser-based noVNC access on port **6080**
* Automatic Chromium restart on crash
* Idle timeout enforcement with forced browser reset
* Non-root execution model
* Environment-driven configuration

---

## Default access credentials

> **Default VNC / noVNC password:** `changeme`

⚠️ This password should be changed if the container is accessed from another machine or network.

---

## Typical use cases

* Classroom and teaching labs
* GNS3 and network simulation environments
* Secured browsing kiosks
* Digital signage and demo stations
* Remote Linux workstation concepts

---

## Quick Start

```bash
docker run -it \
  -p 5900:5900 \
  -p 6080:6080 \
  your-dockerhub-username/chromium-kiosk
```

Then connect using:

* **VNC client:** `localhost:5900`
* **noVNC (web browser):** `http://localhost:6080`

Login password:

```
changeme
```

---

## Advanced Start (Docker Desktop – Optional Settings)

When running this image from **Docker Desktop**, additional configuration can be applied using **Optional Settings**.

These settings allow you to customize the kiosk behavior **without modifying or rebuilding the image**.

### Required optional settings

**Ports**

* `5900` → VNC access
* `6080` → noVNC web access

---

### Optional environment variables

Environment variables can be added in **Docker Desktop → Run → Optional Settings → Environment variables**.

| Variable                       | Description                               | Default                     |
| ------------------------------ | ----------------------------------------- | --------------------------- |
| `KIOSK_URL`                    | URL opened when Chromium starts or resets | `https://www.wikipedia.org` |
| `VNC_PASSWORD`                 | Password for VNC and noVNC access         | `changeme`                  |
| `SCREEN_WIDTH`                 | Virtual screen width                      | `1366`                      |
| `SCREEN_HEIGHT`                | Virtual screen height                     | `768`                       |
| `SCREEN_DEPTH`                 | Color depth                               | `24`                        |
| `NOVNC_ENABLE`                 | Enable or disable noVNC                   | `true`                      |
| `IDLE_TIMEOUT_SECONDS`         | Seconds before idle reset                 | `300`                       |
| `CHROME_RESTART_DELAY_SECONDS` | Delay before Chromium restarts            | `2`                         |

Example:

```
VNC_PASSWORD=mysecurepassword
KIOSK_URL=https://www.google.com
SCREEN_WIDTH=1920
SCREEN_HEIGHT=1080
```

---

### Optional volumes

You may optionally mount a volume to persist browser data:

* **Container path:** `/home/app`

This allows Chromium settings, cache, and profile data to persist across restarts.

If no volume is provided, the container will still run, but browser data will reset when the container stops.

---

## Design philosophy

This image intentionally avoids systemd and full desktop environments.

Instead, it uses:

* explicit process supervision
* lightweight GUI components
* predictable startup order
* clean separation of responsibilities

This makes the image stable, portable, and well-suited for instructional use.

---

## Security notes

* VNC and noVNC are unencrypted by default
* Do not expose ports 5900 or 6080 to public networks
* Use SSH tunneling or HTTPS reverse proxy for remote access

