## 📤 Publishing the Image to Docker Hub

This project is designed so the **same container image** can be:

* built locally for development, **or**
* pulled from Docker Hub and run without source code

Publishing to Docker Hub turns your container into a **distributable artifact**, not just a dev tool.

---

### 🧠 Conceptual Model (Important)

> **GitHub** stores source code
> **Docker Hub** stores built images
> **Compose / Docker Run** consumes images

Once an image is on Docker Hub:

* users do **not** need the repository
* users do **not** need the Dockerfile
* only **ports + environment variables** matter

This is how containers are used in the real world.

---

## 1️⃣ One-Time Setup (Per Machine)

### Create a Docker Hub account

[https://hub.docker.com](https://hub.docker.com)

Your Docker Hub username becomes part of the image name:

```text
<dockerhub-username>/alpine-chromium-kiosk
```

---

### Log in from the CLI

```bash
docker login
```

> ⚠️ If you use MFA, create a **Docker Hub access token** and use it as your password.

Verify login:

```bash
docker info | grep Username
```

---

## 2️⃣ Build the Image Locally

From the **root of the repository**:

```bash
docker build -t alpine-chromium-kiosk:latest .
```

This creates a **local image** only.

---

## 3️⃣ Tag the Image for Docker Hub

Docker Hub requires the image name format:

```text
<username>/<repository>:<tag>
```

Tag your local image:

```bash
docker tag alpine-chromium-kiosk:latest \
  yourdockerhubuser/alpine-chromium-kiosk:latest
```

Confirm:

```bash
docker images | grep alpine-chromium-kiosk
```

You should see **two tags pointing to the same image ID**.

---

## 4️⃣ Push the Image to Docker Hub

```bash
docker push yourdockerhubuser/alpine-chromium-kiosk:latest
```

When complete:

* visit Docker Hub
* confirm the repository exists
* confirm the `latest` tag is visible

---

## 5️⃣ Test the Published Image (Critical Step)

Always test the **pulled image**, not your local build.

Remove local copies:

```bash
docker rmi alpine-chromium-kiosk:latest
docker rmi yourdockerhubuser/alpine-chromium-kiosk:latest
```

Now run using the **Hub profile**:

```bash
make hub
```

If VNC works now, your image is:

* self-contained
* portable
* correctly published

---

## 6️⃣ Versioned Tags (Recommended Best Practice)

Avoid relying only on `latest`.

Tag releases explicitly:

```bash
docker tag alpine-chromium-kiosk:latest \
  yourdockerhubuser/alpine-chromium-kiosk:1.0.0

docker push yourdockerhubuser/alpine-chromium-kiosk:1.0.0
```

Then pin the version in Compose:

```yaml
image: yourdockerhubuser/alpine-chromium-kiosk:1.0.0
```

This prevents:

* unexpected breaking changes
* “it worked last week” problems in labs

---

## 7️⃣ Publishing via Makefile (Recommended)

The included `Makefile` provides a simple CI-style workflow.

### Publish an image

```bash
make publish VERSION=1.0.0
```

This runs:

1. `docker build`
2. `docker tag`
3. `docker push`

Using Make reinforces:

* repeatability
* standard workflows
* separation of concerns

---

## 8️⃣ Common Publishing Mistakes (and Why)

### ❌ “It works locally but not from Docker Hub”

Cause:

* image depended on bind-mounted files
* `.dockerignore` excluded required scripts
* ENTRYPOINT not copied correctly

Fix:

* always test **after pulling**

---

### ❌ “Ports are exposed but unreachable”

Cause:

* `EXPOSE` in Dockerfile
* but **no published ports at runtime**

Fix:

* always use `ports:` (Compose) or `-p` (docker run)

---

### ❌ “Students can’t push images”

Cause:

* MFA enabled
* password used instead of access token

Fix:

* use Docker Hub access tokens

---
