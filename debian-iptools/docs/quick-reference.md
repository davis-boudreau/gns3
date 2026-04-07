# Debian IP Tools Quick Reference

This quick reference is the short version of the project documentation. For the deeper guide, examples, and workflows, see `docs/full-manual.md`.

## Access

- GNS3: open the node console
- Docker Compose: `docker compose exec iptoolkit bash`
- SSH: `ssh root@localhost -p 2222`

Default SSH password:

```text
iptools
```

## First Commands

```bash
ip addr
ip route
hostname
pwd
```

## Core Diagnostics

```bash
ping 192.0.2.1
fping -a -g 192.0.2.0/24
tracepath 192.0.2.1
traceroute 192.0.2.1
mtr -rw 192.0.2.1
```

## DNS and HTTP

```bash
dig example.com
dig @192.0.2.53 example.com
drill example.com
curl -I http://192.0.2.10
curl -vk https://192.0.2.10
http http://192.0.2.10
openssl s_client -connect example.com:443
```

## Packet Capture

```bash
tcpdump -ni eth0
tcpdump -ni eth0 host 192.0.2.10
tcpdump -ni eth0 port 53
tcpdump -ni eth0 -w /work/capture.pcap
tshark -i eth0
ngrep -d eth0 "GET|POST"
```

## Ports and Throughput

```bash
nc -vz 192.0.2.10 22
ncat -vz 192.0.2.10 443
iperf3 -s
iperf3 -c 192.0.2.20
nuttcp -S
nuttcp 192.0.2.20
```

## Firewall and Sessions

```bash
iptables -L -n -v
iptables -t nat -L -n -v
nft list ruleset
conntrack -L
```

## Monitoring

```bash
iftop -i eth0
nethogs eth0
bmon
vnstat -i eth0
```

## Quick GNS3 Workflows

Basic connectivity:

```bash
ip addr
ip route
ping 10.0.0.1
```

DNS check:

```bash
dig router.lab.local
dig @10.0.0.53 example.com
```

Port test:

```bash
nc -vz 10.0.0.20 443
```

Capture:

```bash
tcpdump -ni eth0
```

## Next Step

For tool explanations, scenario-based troubleshooting, and longer examples, read `docs/full-manual.md`.
