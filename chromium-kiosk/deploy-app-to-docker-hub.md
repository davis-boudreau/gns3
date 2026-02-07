## 1) Create a Docker Hub repo

1. Log in to Docker Hub (web)
2. **Create repository**

   * Name: `chromium-kiosk` (or whatever you want)
   * Visibility: Public/Private

Your image name will be:

* `YOUR_DOCKERHUB_USERNAME/chromium-kiosk`

---

## 2) Login from your machine

In PowerShell:

```powershell
docker login
```

(Enter Docker Hub username + password or token.)

---

## 3) Build the image locally

From the folder that contains your `docker-compose.yml` / `Dockerfile`:

```powershell
docker compose build
```

This should produce your local image (you currently name it `alpine-chromium-kiosk:latest` via compose).

Verify:

```powershell
docker images
```

---

## 4) Tag the image for Docker Hub

Tag your local image with the Docker Hub repo name:

```powershell
docker tag alpine-chromium-kiosk:latest YOUR_DOCKERHUB_USERNAME/chromium-kiosk:1.0.0
docker tag alpine-chromium-kiosk:latest YOUR_DOCKERHUB_USERNAME/chromium-kiosk:latest
```

(Use a real version you like: `1.0.0`, `2026.01`, etc.)

---

## 5) Push to Docker Hub

```powershell
docker push YOUR_DOCKERHUB_USERNAME/chromium-kiosk:1.0.0
docker push YOUR_DOCKERHUB_USERNAME/chromium-kiosk:latest
```

---

## 6) Test that it pulls on a “clean” machine

On any machine with Docker:

```powershell
docker pull YOUR_DOCKERHUB_USERNAME/chromium-kiosk:latest
```

And run using your compose setup by changing your compose image to that repo, or by just pulling and running your existing compose.

---

# Optional but recommended upgrades

## A) Add a `.dockerignore`

This keeps your image builds clean and fast (don’t upload local junk into build context). Typical:

* `.git/`
* `node_modules/`
* `*.log`
* `.vscode/`
* `kiosk-home` (if it exists locally)

## B) Multi-arch image (if you ever want ARM + x86)

If you want it to run on Raspberry Pi / Apple Silicon / etc., use Docker Buildx and push a multi-arch manifest. I can give you the exact commands when you’re ready.

## C) Use a Docker Hub access token

More secure than password, especially for CI/CD.

---
