# Alpine PostgreSQL

Alpine PostgreSQL is a lightweight PostgreSQL container project for Docker and GNS3 labs. It is built on top of the official `postgres:16-alpine` image and packaged as a simple appliance-friendly database node.

## What This Project Is For

- Running PostgreSQL in GNS3 topologies
- Pairing with `pgAdmin`, application servers, or test clients
- Teaching SQL, authentication, and service connectivity
- Testing firewall, NAT, routing, and port reachability to a database service
- Troubleshooting connectivity from inside the node with an Alpine shell

## Files

- `Dockerfile` builds a minimal Alpine-based PostgreSQL image
- `gns3-entrypoint.sh` starts PostgreSQL in the background when the node is launched from a GNS3 console shell
- `docker-compose.yml` runs the database locally with a persistent data volume
- `postgres.env` stores the main initialization variables
- `alpine-postgres.gns3a` is the GNS3 appliance file
- `initdb/` is for optional first-run SQL or shell initialization scripts

## Environment Variables

```env
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=postgres
PGDATA=/var/lib/postgresql/data/pgdata
TZ=UTC
```

Notes:

- `POSTGRES_USER`, `POSTGRES_PASSWORD`, and `POSTGRES_DB` are used only when the database initializes for the first time
- If the data volume already exists, changing those variables does not reset the existing database
- `PGDATA` keeps the initialized cluster under a dedicated subdirectory in the mounted volume
- `GNS3_SHELL_MODE=true` starts PostgreSQL for GNS3 shell mode without tying database uptime to the interactive shell session

## Local Usage

Build the image:

```bash
make build
```

Start PostgreSQL:

```bash
make up
```

View logs:

```bash
make logs
```

Open a shell inside the container:

```bash
make shell
```

Connect with `psql` inside the running container:

```bash
make psql
```

Stop the container:

```bash
make down
```

## Docker Compose Behavior

- PostgreSQL is exposed on port `5432`
- Data is persisted in the `postgres_data` Docker volume
- `./initdb` is mounted to `/docker-entrypoint-initdb.d` for optional first-run initialization scripts
- A healthcheck uses `pg_isready` to confirm the service is accepting connections

## GNS3 Usage

Import `alpine-postgres.gns3a` into GNS3 and add the node to your topology.

Typical workflow:

1. Place the PostgreSQL node in the topology.
2. Connect it to the same network as your clients, app servers, or pgAdmin node.
3. Start the node.
4. Open the console to access the Alpine shell inside the node.
5. Ensure the node has working IP configuration in GNS3.
6. Verify PostgreSQL is ready, then connect to the service on port `5432`.

Useful GNS3 console commands:

```sh
ip addr
ip route
ping 10.0.0.1
pg_isready -U postgres -d postgres
psql -U postgres -d postgres
tail -f /var/log/postgresql/postgresql.log
ss -lntp
```

Common clients:

- `pgAdmin`
- `psql`
- Custom applications
- The `alpine-pgadmin-chromium` project

Default example credentials:

```text
User: postgres
Password: postgres
Database: postgres
Port: 5432
```

Important for GNS3:

- `PGDATA` should remain set to `/var/lib/postgresql/data/pgdata`
- This avoids PostgreSQL trying to initialize directly on the Docker mount point, which can fail because the mount path is not empty

## Initialization Scripts

You can place `.sql`, `.sql.gz`, or executable `.sh` files in `initdb/`.

These scripts run only when PostgreSQL initializes a new data directory for the first time.

Example:

```sql
CREATE TABLE demo (
  id serial PRIMARY KEY,
  name text NOT NULL
);
```

## Notes

- This project intentionally stays close to the official PostgreSQL image behavior for normal Docker and Compose runs
- In GNS3, PostgreSQL is forced to listen on all interfaces so other lab nodes can reach it on port `5432`
- In GNS3, the console is designed to be a practical troubleshooting shell with PostgreSQL already running
- For visual administration, pair this node with pgAdmin
