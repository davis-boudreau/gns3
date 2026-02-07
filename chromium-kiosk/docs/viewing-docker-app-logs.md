Ah — got it 👍
You mean **inside the running container**, not `docker logs`. Perfect question.

Because those files live **inside the container filesystem**, you have three clean options.

---

# ✅ Option 1 — View logs live (best)

```bash
docker exec -it alpine-chromium-kiosk tail -f /tmp/chromium.log
```

You can replace the filename:

```bash
docker exec -it alpine-chromium-kiosk tail -f /tmp/fluxbox.log
```

```bash
docker exec -it alpine-chromium-kiosk tail -f /tmp/x11vnc.log
```

This is the **best way while debugging GUI apps**.

---

# ✅ Option 2 — View last lines only

```bash
docker exec -it alpine-chromium-kiosk tail -n 200 /tmp/chromium.log
```

Useful if Chromium crashes immediately.

---

# ✅ Option 3 — Open an interactive shell

```bash
docker exec -it alpine-chromium-kiosk sh
```

Then inside the container:

```sh
ls -l /tmp
cat /tmp/chromium.log
less /tmp/chromium.log
```

(Alpine doesn’t include `less` by default, so `cat` or `tail` is usually used.)

Exit with:

```sh
exit
```

---

# 🧠 Why this works

Those logs are written by your **entrypoint**, not Docker itself.

So:

* `docker logs` → container stdout/stderr
* `/tmp/*.log` → internal process logs

Both are valid, but they answer different questions.

---

# 🔍 What to check first (when you paste logs)

When you send the Chromium log, I’ll look specifically for:

* display / X errors
* sandbox or namespace errors
* DBus errors
* GPU / EGL / GL failures
* fontconfig or NSS failures

These usually show up **clearly** once the architecture is correct (which it now is).

---

Go ahead and paste:

```bash
docker exec -it alpine-chromium-kiosk tail -n 200 /tmp/chromium.log
```

