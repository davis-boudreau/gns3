# Alpine pgAdmin Chromium

Alpine pgAdmin Chromium is a GNS3-friendly browser appliance that combines a VNC-accessible Chromium desktop with a local pgAdmin web service. It is meant for PostgreSQL labs where users want a ready-made browser node that opens directly into pgAdmin.

## What It Does

- Starts pgAdmin inside the container
- Starts a VNC desktop with Chromium
- Opens Chromium to the local pgAdmin URL by default
- Optionally pre-registers a PostgreSQL server in pgAdmin from environment variables
- Works as a standalone Docker container or as a GNS3 Docker appliance

## Main Files

- `Dockerfile` builds the combined pgAdmin + Chromium image
- `entrypoint.sh` starts pgAdmin, VNC, noVNC, Fluxbox, and Chromium
- `pgadmin-chromium.env` stores browser, pgAdmin, and PostgreSQL target settings
- `docker-compose.yml` runs the container locally
- `alpine-pgadmin-chromium.gns3a` is the GNS3 appliance file

## Environment Variables

Browser and VNC:

```env
ACCESS_MODE=standalone
BROWSER_MODE=full
SCREEN_WIDTH=1920
SCREEN_HEIGHT=1080
SCREEN_DEPTH=24
DEFAULT_URL=http://127.0.0.1:5050
VNC_PASSWORD=mylabpass
NOVNC_ENABLE=true
IDLE_TIMEOUT_SECONDS=0
```

pgAdmin:

```env
PGADMIN_DEFAULT_EMAIL=admin@example.com
PGADMIN_DEFAULT_PASSWORD=admin
PGADMIN_LISTEN_ADDRESS=0.0.0.0
PGADMIN_LISTEN_PORT=5050
PGADMIN_AUTO_SETUP=true
```

PostgreSQL target registration:

```env
PGADMIN_SERVER_NAME=Lab PostgreSQL
PGADMIN_SERVER_GROUP=Servers
PGADMIN_SERVER_HOST=postgres
PGADMIN_SERVER_PORT=5432
PGADMIN_SERVER_MAINTENANCE_DB=postgres
PGADMIN_SERVER_USERNAME=postgres
PGADMIN_SERVER_PASSWORD=postgres
PGADMIN_SERVER_SSLMODE=prefer
```

## Local Usage

Build:

```bash
make build
```

Run:

```bash
make up
```

Access options:

- VNC: `localhost:5900`
- noVNC: `http://localhost:8080`
- pgAdmin directly: `http://localhost:5050`

Default pgAdmin login:

```text
Email: admin@example.com
Password: admin
```

Stop:

```bash
make down
```

## GNS3 Usage

Import `alpine-pgadmin-chromium.gns3a` into GNS3 and add the node to your project.

Recommended GNS3 flow:

1. Place the node in the topology.
2. Connect it to the network that can reach your PostgreSQL server.
3. Open Node Properties and configure DHCP or a static IPv4 address.
4. Set `PGADMIN_SERVER_HOST` to the reachable PostgreSQL IP or DNS name.
5. Start the node.
6. Open the VNC console.
7. Chromium will load pgAdmin automatically.

## Notes

- `ACCESS_MODE=gns3` disables the VNC password for the built-in GNS3 console workflow.
- `PGADMIN_AUTO_SETUP=true` writes a pgAdmin server entry from the environment file at startup.
- `DEFAULT_URL` normally points to the local pgAdmin service on port `5050`.
- The project name keeps the existing Alpine Chromium naming pattern, but this image is built on top of the official `dpage/pgadmin4` base so pgAdmin setup is reliable.
