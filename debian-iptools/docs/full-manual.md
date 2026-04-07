# Debian IP Tools Full Manual

This manual describes the main tools installed in the `debian-iptools` container and how to use them in lab, Docker, and GNS3 environments.

The container is designed as a general-purpose network toolbox. Most commands are meant to be run from:

- The GNS3 node console
- `docker compose exec iptoolkit bash`
- An SSH session into the container

If you only want the short version, start with `docs/quick-reference.md`.

## Before You Start

Useful first checks:

```bash
ip addr
ip route
hostname
pwd
```

Notes:

- The default working directory is `/work`
- In GNS3, your main test interface is often `eth0`
- Some commands need `NET_ADMIN` or `NET_RAW`, which the main container already has
- Packet capture and traffic tools are most useful when you know the right interface name

## Quick Troubleshooting Flow

When a network path is not working, a simple workflow is:

1. Check interface status with `ip addr` and `ip link`
2. Check routes with `ip route`
3. Test reachability with `ping` or `fping`
4. Trace the path with `tracepath`, `traceroute`, or `mtr`
5. Test service ports with `nc`, `ncat`, or `curl`
6. Capture traffic with `tcpdump` or `tshark`
7. Inspect firewall state with `iptables`, `nft`, or `conntrack`

## Layer 2 and Layer 3 Tools

### `ip`

Primary Linux networking command for interfaces, addresses, and routes.

Examples:

```bash
ip addr
ip link
ip route
ip neigh
```

Common use:

- See IP addresses on interfaces
- Verify default gateway
- Check ARP and neighbor entries

### `ifconfig`, `route`, `netstat`

Legacy tools from `net-tools`. Useful when older documentation expects them.

Examples:

```bash
ifconfig
route -n
netstat -rn
```

### `ethtool`

Shows Ethernet interface details such as link state, speed, and driver information.

Examples:

```bash
ethtool eth0
ethtool -i eth0
```

### `ping`

Basic ICMP reachability test.

Examples:

```bash
ping 192.168.1.1
ping -c 4 8.8.8.8
```

Use it to confirm:

- Host reachability
- Packet loss
- Basic latency

### `fping`

Fast ping tool, especially useful for multiple hosts.

Examples:

```bash
fping 192.168.1.1 192.168.1.2 192.168.1.3
fping -a -g 192.168.1.0/24
```

### `tracepath`

Simple path-discovery tool that does not require as much setup as `traceroute`.

Example:

```bash
tracepath 8.8.8.8
```

### `traceroute`

Shows the routed path to a destination.

Examples:

```bash
traceroute 8.8.8.8
traceroute -n 192.168.50.10
```

### `mtr`

Combines `ping` and `traceroute` into a continuous path quality tool.

Examples:

```bash
mtr 8.8.8.8
mtr -rw 8.8.8.8
```

Use `-rw` for a report-style output that is easier to save.

### `arping`

Tests Layer 2 reachability using ARP on the local subnet.

Examples:

```bash
arping -I eth0 192.168.1.1
```

Useful for:

- Verifying local subnet presence
- Detecting duplicate IPs
- Confirming ARP replies

### `arp-scan`

Scans a local subnet for live devices using ARP.

Examples:

```bash
arp-scan --interface=eth0 --localnet
```

## DNS and Application Layer Tools

### `dig`

DNS query tool for detailed lookups.

Examples:

```bash
dig example.com
dig @8.8.8.8 example.com
dig example.com MX
```

### `drill`

Alternative DNS lookup tool from `ldnsutils`.

Example:

```bash
drill example.com
```

### `nslookup`

Basic DNS query tool. Simpler than `dig`, but less detailed.

Example:

```bash
nslookup example.com
```

### `curl`

Flexible HTTP, HTTPS, and API client.

Examples:

```bash
curl http://192.168.1.10
curl -I https://example.com
curl -vk https://192.168.1.10
```

Useful for:

- Testing web servers
- Seeing HTTP headers
- Troubleshooting TLS issues

### `wget`

Another HTTP and HTTPS client, often used for quick downloads.

Example:

```bash
wget -O- http://192.168.1.10
```

### `http`

Command from `httpie`, useful for readable HTTP requests.

Examples:

```bash
http http://192.168.1.10
http GET https://example.com
```

### `openssl`

Useful for checking certificates and testing TLS services.

Example:

```bash
openssl s_client -connect example.com:443
```

## Performance and Transport Tools

### `iperf3`

Measures TCP or UDP throughput between two hosts.

Server:

```bash
iperf3 -s
```

Client:

```bash
iperf3 -c 192.168.1.20
iperf3 -c 192.168.1.20 -u
```

Useful for:

- Throughput testing
- UDP loss and jitter testing
- Comparing links before and after changes

### `nuttcp`

Another throughput and transport test tool.

Examples:

```bash
nuttcp -S
nuttcp 192.168.1.20
```

### `nc`

Netcat from `netcat-openbsd`. Great for quick port tests and simple listeners.

Examples:

```bash
nc -vz 192.168.1.10 22
nc -l -p 9000
```

### `ncat`

Nmap's enhanced netcat implementation.

Examples:

```bash
ncat -vz 192.168.1.10 443
ncat -l 8080
```

### `socat`

Advanced socket relay and port forwarding tool.

Example:

```bash
socat TCP-LISTEN:8080,fork TCP:192.168.1.10:80
```

Use it when you need:

- Port forwarding
- Protocol bridging
- Lightweight relays for testing

## Packet Capture and Analysis

### `tcpdump`

Classic CLI packet capture tool.

Examples:

```bash
tcpdump -ni eth0
tcpdump -ni eth0 host 192.168.1.10
tcpdump -ni eth0 port 53
tcpdump -ni eth0 -w capture.pcap
```

Use it for:

- Quick packet inspection
- Saving captures to review later
- Verifying whether traffic is arriving or leaving

### `tshark`

Terminal version of Wireshark with strong filtering and decode support.

Examples:

```bash
tshark -i eth0
tshark -i eth0 -f "port 53"
tshark -r capture.pcap
```

### `ngrep`

Searches packet payloads using patterns, similar to grep for network traffic.

Example:

```bash
ngrep -d eth0 "GET|POST"
```

### `tcpreplay`

Replays packets from an existing capture file.

Example:

```bash
tcpreplay -i eth0 capture.pcap
```

Useful for:

- Reproducing traffic conditions
- Testing IDS, firewalls, or service behavior

## Firewall, NAT, and Connection Tracking

### `iptables`

Shows or manages legacy Linux firewall rules.

Examples:

```bash
iptables -L -n -v
iptables -t nat -L -n -v
```

### `nft`

Shows or manages modern Linux firewall rules with nftables.

Examples:

```bash
nft list ruleset
nft list tables
```

### `conntrack`

Inspects tracked network sessions.

Examples:

```bash
conntrack -L
conntrack -L | grep 192.168.1.10
```

Useful for:

- Seeing active flows
- Checking NAT state
- Troubleshooting stale sessions

## Security and Scanning Tools

### `nmap`

Port scanner and service discovery tool.

Examples:

```bash
nmap 192.168.1.10
nmap -sV 192.168.1.10
nmap -Pn 192.168.1.0/24
```

### `hping3`

Crafts custom TCP, UDP, or ICMP packets for testing.

Examples:

```bash
hping3 -S -p 80 192.168.1.10
hping3 --icmp 192.168.1.10
```

Use carefully in shared environments.

## Monitoring Tools

### `iftop`

Shows bandwidth usage by host pair in real time.

Example:

```bash
iftop -i eth0
```

### `nethogs`

Shows bandwidth usage by process.

Example:

```bash
nethogs eth0
```

### `bmon`

Terminal bandwidth monitor with interface-level charts.

Example:

```bash
bmon
```

### `vnstat`

Tracks traffic counters over time.

Examples:

```bash
vnstat
vnstat -i eth0
```

### `procps` tools

Includes general process and system tools such as:

- `ps`
- `top`
- `free`
- `uptime`

Useful for checking whether the container itself is resource constrained.

## Wireless Tools

### `iw`

Wireless interface inspection and configuration tool.

Example:

```bash
iw dev
```

### `wavemon`

Interactive wireless monitoring tool.

Run:

```bash
wavemon
```

These tools are only useful if the environment actually exposes wireless interfaces to the container.

## SSH and General Utilities

### `ssh`

SSH client for remote access to other systems.

Example:

```bash
ssh user@192.168.1.10
```

### `rsync`

Efficient file transfer and sync tool.

Example:

```bash
rsync -av /work/ user@192.168.1.10:/tmp/work/
```

### `jq`

Command-line JSON parser.

Example:

```bash
curl -s http://192.168.1.10/api | jq .
```

### `whois`

Looks up registration information for domains and IP ranges.

Example:

```bash
whois example.com
```

### `less`

Pager for reading long command output.

Example:

```bash
ip route | less
```

## Common GNS3 Use Cases

### Validate basic connectivity

```bash
ip addr
ip route
ping 10.0.0.1
```

### Troubleshoot DNS

```bash
dig router.lab.local
dig @10.0.0.53 example.com
```

### Test a web server

```bash
curl -I http://10.0.0.20
curl -vk https://10.0.0.20
```

### Capture packets on the attached segment

```bash
tcpdump -ni eth0
```

### Check whether a port is open

```bash
nc -vz 10.0.0.20 443
```

### Measure throughput

On one node:

```bash
iperf3 -s
```

On another:

```bash
iperf3 -c 10.0.0.20
```

## Real Lab Scenarios

### DNS Failure Workflow

Symptoms:

- Hostnames do not resolve
- `ping` by IP works, but `ping` by name fails
- Applications time out while looking up names

Suggested workflow:

1. Confirm basic connectivity:

```bash
ip addr
ip route
ping -c 4 10.0.0.53
```

2. Check resolver settings:

```bash
cat /etc/resolv.conf
```

3. Query the expected DNS server directly:

```bash
dig @10.0.0.53 example.com
dig @10.0.0.53 router.lab.local
```

4. Compare with another resolver:

```bash
dig @8.8.8.8 example.com
```

5. Capture DNS traffic if needed:

```bash
tcpdump -ni eth0 port 53
```

What to look for:

- No reply at all usually points to routing, firewall, or server reachability
- `SERVFAIL` points to an upstream or recursive resolver problem
- `NXDOMAIN` means the queried name does not exist in that zone

### NAT Debugging Workflow

Symptoms:

- Internal hosts can send traffic out, but replies do not come back
- Sessions work one way only
- Internet access works intermittently

Suggested workflow:

1. Validate local addressing and route:

```bash
ip addr
ip route
```

2. Test end-to-end connectivity:

```bash
ping -c 4 8.8.8.8
curl -I http://example.com
```

3. Review firewall and NAT rules:

```bash
iptables -L -n -v
iptables -t nat -L -n -v
nft list ruleset
```

4. Inspect connection tracking entries:

```bash
conntrack -L | grep 10.0.0.
```

5. Capture both sides of the path when possible:

```bash
tcpdump -ni eth0 host 10.0.0.10
```

What to look for:

- Missing `MASQUERADE` or `SNAT` rules
- Return traffic arriving with no matching conntrack state
- Asymmetric routing where replies return through a different device

### Packet Capture Workflow

Symptoms:

- Application fails but logs are unclear
- Packets are suspected to be dropped or rewritten
- You need proof of what is actually on the wire

Suggested workflow:

1. Identify the right interface:

```bash
ip addr
ip link
```

2. Start with a broad capture:

```bash
tcpdump -ni eth0
```

3. Narrow by host or port:

```bash
tcpdump -ni eth0 host 10.0.0.20
tcpdump -ni eth0 port 443
```

4. Save a capture for later review:

```bash
tcpdump -ni eth0 -w /work/problem.pcap
```

5. Review it with `tshark`:

```bash
tshark -r /work/problem.pcap
```

What to look for:

- SYN packets with no SYN-ACK
- DNS queries with no responses
- ICMP unreachable messages
- TLS handshakes that stop after client hello or certificate exchange

## Tips

- Start with `ip addr` and `ip route` before running more advanced tools
- Use `tcpdump` when you are unsure whether traffic is even reaching the node
- Use `mtr` for path quality, not just simple up-or-down testing
- Use `curl -vk` and `openssl s_client` when HTTPS behaves differently than HTTP
- Use `conntrack -L` when traffic appears to be blocked by stale session state

## Reference

To see all installed packages, review:

- `Dockerfile`
- `docs/packages.md`

For tool-specific flags, use built-in help:

```bash
<tool> --help
man <tool>
```
