# Alpine Chromium Kiosk (VNC / noVNC)

A **containerized Chromium kiosk** built on Alpine Linux using:

* **TigerVNC (Xvnc)** — virtual X server + VNC in one process
* **Fluxbox** — lightweight window manager
* **Chromium** — kiosk-mode browser with watchdog + idle reset
* **noVNC (optional)** — browser-based VNC access

This project is designed for **teaching containers, ports, and runtime configuration** as well as for real kiosk deployments.

---

## 🧠 Architecture Overview (Mental Model)

> **Dockerfile** = *what the system is*
> **Image** = *a sealed appliance*
> **Compose** = *how the appliance is plugged into the host*

If ports are not published, the kiosk **will run but be unreachable**.

---

## 🚀 Quick Start

### Option 1 — Dev Mode (build from local source)

```bash
make dev
```

### Option 2 — Hub Mode (pull from Docker Hub)

```bash
make hub
```

### Connect

* **VNC:** `localhost:5900`
* **noVNC:** `http://localhost:6080`
  *(only when `ACCESS_MODE=standalone` and `NOVNC_ENABLE=true`)*

---

## 🧩 Compose Profiles (Dev vs Hub)

This project uses **Docker Compose profiles** so we can use **one compose file** for two workflows.

### Profiles

| Profile | What it does                                  |
| ------- | --------------------------------------------- |
| `dev`   | Builds the image locally from this repository |
| `hub`   | Pulls a pre-built image from Docker Hub       |

### Why profiles matter

* Students **don’t need the source code** to run the kiosk
* Instructors can **guarantee image parity**
* Avoids “it worked on my machine” problems

---

## 📦 `docker-compose.yml` (Conceptual)

```yaml
services:
  kiosk:        # dev profile → build from repo
  kiosk-hub:    # hub profile → pull from Docker Hub
```

Only **one service runs at a time**, but both share:

* the same container name
* the same ports
* the same volume
* the same environment variables

---

## 🔌 Ports Explained (Most Common Failure Point)

### Inside the container

| Service            | Port |
| ------------------ | ---- |
| Xvnc (VNC server)  | 5900 |
| noVNC / websockify | 6080 |

### Published to the host

```yaml
ports:
  - "5900:5900"
  - "6080:6080"
```

> ⚠️ **Important**
>
> `EXPOSE 5900` in the Dockerfile **does not make the port reachable**.
> Ports are only reachable when explicitly **published** using:
>
> * `ports:` in Compose
> * `-p` in `docker run`

This is the #1 reason containers “work” but cannot be connected to.

---

## 🔁 Host ↔ Container Port Flow

```text
VNC Client (Student)
        |
        |  TCP 5900
        v
Host OS (Windows / Linux / macOS)
        |
        |  docker port publish (-p 5900:5900)
        v
Docker Engine
        |
        |  container port 5900
        v
Xvnc (TigerVNC)
        |
        v
Fluxbox → Chromium (Kiosk)
```

For noVNC:

```text
Browser → http://localhost:6080 → websockify → Xvnc
```

---

## ⚙️ Environment Configuration (`kiosk.env`)

Behavior is controlled **at runtime**, not build time.

Common variables:

```env
ACCESS_MODE=standalone     # or gns3
VNC_PASSWORD=changeme
NOVNC_ENABLE=true
KIOSK_URL=https://www.google.com
```

Why this matters:

* Same image, different behavior
* Safe for labs
* No rebuilds required

---

## 🧪 Makefile Commands

| Command      | Purpose                                |
| ------------ | -------------------------------------- |
| `make dev`   | Build locally and run                  |
| `make hub`   | Pull from Docker Hub and run           |
| `make logs`  | Follow container logs                  |
| `make ports` | Show published ports                   |
| `make shell` | Shell into container                   |
| `make down`  | Stop container                         |
| `make reset` | Stop + delete container **and volume** |

---

## 🧯 Troubleshooting

### ❌ “VNC won’t connect”

Check ports:

```bash
make ports
```

Expected:

```text
5900/tcp -> 0.0.0.0:5900
6080/tcp -> 0.0.0.0:6080
```

If empty → ports are not published.

---

### ❌ Container runs but no display

Check logs:

```bash
make logs
```

Then:

```bash
docker exec -it alpine-chromium-kiosk ss -lntp
```

Ensure Xvnc is listening on:

```text
0.0.0.0:5900
```

---

### ❌ noVNC page loads but shows black screen

Confirm:

* `ACCESS_MODE=standalone`
* `NOVNC_ENABLE=true`
* Xvnc is running

---

## 🎓 Teaching Takeaways

Students learn:

* Difference between **EXPOSE vs published ports**
* Immutable images vs runtime configuration
* Why Compose exists
* How real kiosk containers are deployed
* Why “it’s running” ≠ “it’s reachable”

---

## ✅ Summary

This repository demonstrates **real-world container design**:

* One image
* Multiple deployment modes
* Explicit networking
* Clear separation of build vs run
* Deterministic behavior across environments

If you can run this kiosk correctly, you understand **Docker networking fundamentals**.

---
