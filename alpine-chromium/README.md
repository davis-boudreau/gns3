# Alpine Chromium for GNS3

![Docker Pulls](https://img.shields.io/docker/pulls/davisboudreau/alpine-chromium)
![Docker Image Size](https://img.shields.io/docker/image-size/davisboudreau/alpine-chromium/latest)
![Docker Stars](https://img.shields.io/docker/stars/davisboudreau/alpine-chromium)
![License](https://img.shields.io/badge/license-educational-blue)

A lightweight **Alpine Linux + Chromium Browser** container designed for:

- GNS3 network labs
- browser-based testing
- cybersecurity exercises
- educational environments

This container provides a simple, fast, and flexible browser appliance with **VNC and optional noVNC access**, making it ideal for remote lab environments.

---

## 🚀 Features

- Lightweight Alpine-based image
- Preconfigured Chromium browser
- Built for **GNS3 Docker appliances**
- Supports **VNC remote desktop**
- Optional **noVNC web access (browser-based VNC)**
- Dual operation modes:
  - GNS3 mode
  - Standalone Docker mode
- Dual browser modes:
  - Kiosk (locked)
  - Full (interactive)

---

## 🧠 Modes Overview

### 🔌 Access Modes

| Mode | Description |
|------|------------|
| `gns3` | Optimized for GNS3 lab environments |
| `standalone` | Run independently using Docker |

---

### 🌐 Browser Modes

| Mode | Description |
|------|------------|
| `kiosk` | Full-screen locked browser (no UI controls) |
| `full` | Standard Chromium browser with controls |

---

## ⚙️ Environment Variables

### Default Configuration

```env
ACCESS_MODE=gns3
BROWSER_MODE=full
SCREEN_WIDTH=1920
SCREEN_HEIGHT=1080
DEFAULT_URL=https://www.bing.com
VNC_PASSWORD=mylabpass
NOVNC_ENABLE=true
````

---

### Variable Reference

| Variable        | Required | Description                 |
| --------------- | -------- | --------------------------- |
| `ACCESS_MODE`   | ✅        | `gns3` or `standalone`      |
| `BROWSER_MODE`  | ✅        | `kiosk` or `full`           |
| `SCREEN_WIDTH`  | ✅        | Display width (pixels)      |
| `SCREEN_HEIGHT` | ✅        | Display height (pixels)     |
| `DEFAULT_URL`   | ✅        | URL opened at startup       |
| `VNC_PASSWORD`  | ✅        | VNC authentication password |
| `NOVNC_ENABLE`  | ✅        | Enable/disable noVNC        |

---

## 🐳 Docker Usage

### Run Container (Standalone Mode)

```bash
docker run -d \
  --name alpine-chromium \
  -e ACCESS_MODE=standalone \
  -e BROWSER_MODE=full \
  -e SCREEN_WIDTH=1920 \
  -e SCREEN_HEIGHT=1080 \
  -e DEFAULT_URL=https://www.bing.com \
  -e VNC_PASSWORD=mylabpass \
  -e NOVNC_ENABLE=true \
  davisboudreau/alpine-chromium:latest
```

---

### Accessing the Browser

* **VNC Client** → connect using container IP + password
* **noVNC (if enabled)** → access via browser (port depends on implementation)

---

## 🧪 GNS3 Integration

This container is built specifically for **GNS3 Docker appliances**.

### Recommended Appliance Configuration

| Setting       | Value                                  |
| ------------- | -------------------------------------- |
| Image         | `davisboudreau/alpine-chromium:latest` |
| Adapters      | 1                                      |
| Console       | `VNC`                                  |
| Start Command | `sleep infinity`                       |

---

### GNS3 Environment Example

```env
ACCESS_MODE=gns3
SCREEN_WIDTH=1920
SCREEN_HEIGHT=1080
BROWSER_MODE=full
DEFAULT_URL=https://www.bing.com
VNC_PASSWORD=mylabpass
NOVNC_ENABLE=true
```

---

### 🌐 Network Configuration (IMPORTANT)

Inside GNS3:

1. Open **Node Properties**
2. Go to **Network Configuration**
3. Click **Edit**
4. Remove `#` from one option:

   * DHCP configuration
     **OR**
   * Static IPv4 configuration

Without this step, the browser will not have network connectivity.

---

## 🎯 Use Cases

* GNS3 networking labs
* Firewall / proxy testing
* Web server validation
* Captive portal testing
* Cybersecurity exercises
* Classroom demonstrations
* Kiosk-style training environments

---

## 📁 Project Resources

* 🔗 Docker Hub: [https://hub.docker.com/r/davisboudreau/alpine-chromium](https://hub.docker.com/r/davisboudreau/alpine-chromium)
* 🔗 GitHub: [https://github.com/davis-boudreau/gns3/tree/main/alpine-chromium](https://github.com/davis-boudreau/gns3/tree/main/alpine-chromium)

---

## 👨‍💻 Maintainer

**Davis Boudreau**
NSCC – Information Technology Programs

---

## ⚠️ Notes

* Default credentials are intended for **lab use only**
* Not recommended for production environments without hardening
* Ensure proper network configuration in GNS3 for connectivity

---

## 🧾 License

Educational use. Modify and adapt for lab environments.

---

## ⭐ Support

If you find this useful:

* ⭐ Star the GitHub repo
* 🐳 Follow on Docker Hub
* 🧑‍🏫 Use in your labs and classrooms

---

