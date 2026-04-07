# Debian IP Tools


![Docker Pulls](https://img.shields.io/docker/pulls/davisboudreau/debian-iptools)
![Docker Image Size](https://img.shields.io/docker/image-size/davisboudreau/debian-iptools/latest)
![Docker Stars](https://img.shields.io/docker/stars/davisboudreau/debian-iptools)
![License](https://img.shields.io/badge/license-MIT-green)

Debian IP Tools is a Debian Slim based network troubleshooting container for labs, testing, and GNS3. It packages a broad set of CLI tools for reachability checks, packet capture, DNS troubleshooting, throughput testing, firewall inspection, and general network diagnostics.

Documentation:

- Quick reference: `docs/quick-reference.md`
- Full manual: `docs/full-manual.md`

The project can be used in two ways:

- As a local Docker or Docker Compose toolbox
- As a Docker appliance inside GNS3

## Features

- Debian Slim base image
- Interactive toolbox container with `/work` mounted for your files
- Built-in SSH service for optional remote shell access
- Optional `iperf3` server profile
- Optional rolling `tshark` capture profile
- GNS3 appliance definition included in the repo

## Included Tools

- Core networking: `iproute2`, `net-tools`, `ethtool`, `iputils-ping`, `tracepath`, `traceroute`, `mtr`, `arping`, `arp-scan`
- DNS and web: `dig`, `drill`, `curl`, `wget`, `http`, `openssl`
- Performance and sockets: `iperf3`, `nuttcp`, `fping`, `nc`, `ncat`, `socat`
- Capture and analysis: `tcpdump`, `tshark`, `ngrep`, `tcpreplay`
- Security and firewall: `nmap`, `hping3`, `iptables`, `nftables`, `conntrack`
- Monitoring: `iftop`, `nethogs`, `bmon`, `vnstat`, `procps`
- General utilities: `jq`, `rsync`, `openssh-client`, `openssh-server`, `whois`, `less`

## Documentation

- `docs/quick-reference.md` for the short command-oriented guide
- `docs/full-manual.md` for tool explanations, workflows, and lab scenarios

## Project Layout

- `Dockerfile` builds the image
- `entrypoint.sh` starts SSH when enabled, then runs the container command
- `docker-compose.yml` defines the main toolbox plus optional `iperf3` and capture services
- `Makefile` wraps common build, run, and publish commands
- `debian-iptools.gns3a` is the GNS3 appliance definition
- `work/` is mounted into the main container as `/work`
- `captures/` is used by the optional rolling `tshark` capture service

## Requirements

- Docker
- Docker Compose
- GNS3, if you want to use the appliance in a topology

## Quick Start

Build the image:

```bash
make build
```

Start the main toolbox container:

```bash
make up
```

Open a shell:

```bash
docker compose exec iptoolkit bash
```

Or connect over SSH with the default local settings:

```bash
ssh root@localhost -p 2222
```

Default SSH password:

```text
iptools
```

Stop the environment:

```bash
make down
```

## Docker Compose Profiles

The Compose file provides three services:

- `iptoolkit`: the primary interactive toolbox
- `iperf3-server`: optional background throughput server
- `tshark-capture`: optional background packet capture writer

Start only the main toolbox:

```bash
make up
```

Start everything:

```bash
make up-all
```

Start the optional services directly:

```bash
docker compose --profile perf up -d iperf3-server
docker compose --profile capture up -d tshark-capture
```

## Configuration

Local defaults are set in `.env`.

| Variable | Default | Purpose |
| --- | --- | --- |
| `IMAGE_NAME` | `iptools` | Local image name |
| `IMAGE_TAG` | `debian-slim` | Local image tag |
| `TZ` | `UTC` | Container timezone |
| `HOSTNAME_OVERRIDE` | `iptoolkit` | Hostname for the main container |
| `CAP_IFACE` | `any` | Capture interface for `tshark-capture` |
| `IPERF_PORT` | `5201` | Exposed `iperf3` port |
| `SSH_PORT` | `2222` | SSH port inside and outside the main container |
| `SSH_USER` | `root` | SSH username |
| `SSH_PASSWORD` | `iptools` | SSH password |

Additional runtime behavior:

- `START_SSH=true` enables the SSH daemon
- The main container exposes `SSH_PORT` and `IPERF_PORT`
- The main container mounts `./work` to `/work`

## Common Commands

Basic diagnostics:

```bash
ip addr
ip route
ping 192.0.2.1
mtr 192.0.2.1
dig example.com
curl http://192.0.2.10
```

Packet capture:

```bash
tcpdump -ni eth0
tshark -i eth0
ngrep -d eth0 .
```

Performance testing:

```bash
iperf3 -c 192.0.2.20
nuttcp 192.0.2.20
```

Firewall and connection inspection:

```bash
iptables -L
nft list ruleset
conntrack -L
```

## Using In GNS3

The repository includes `debian-iptools.gns3a`, which can be imported as a Docker appliance.

Typical GNS3 workflow:

1. Import the appliance into GNS3.
2. Add the node to your topology.
3. Connect it to the segment you want to test.
4. Start the node.
5. Open the node console and run the tools you need.

Notes for GNS3:

- The container is designed to stay running in the background.
- The appliance uses the container entrypoint, not just a bare `sleep` process.
- SSH starts by default inside the container, but the GNS3 console is usually the simplest access method.
- If you want external SSH access, map the SSH port appropriately in your Docker or GNS3 environment.
- Packet capture commands usually need the correct interface name, such as `eth0`.

## Make Targets

```bash
make help
make build
make up
make up-all
make shell
make down
make tag
make push
make publish
```

## Publishing

The project is set up to publish the image as:

```text
davisboudreau/debian-iptools:latest
```

Standard publish flow:

```bash
make build
make tag
make push
```

Or:

```bash
make publish
```

## Notes

- The main toolbox container runs with `NET_ADMIN` and `NET_RAW` capabilities.
- The `iperf3-server` profile disables SSH and runs only the throughput server process.
- The `tshark-capture` profile disables SSH and writes rolling capture files to `./captures`.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.
