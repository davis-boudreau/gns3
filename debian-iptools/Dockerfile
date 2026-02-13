# Full IP/Networking Toolkit on Debian Slim
FROM debian:stable-slim

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm-256color \
    LC_ALL=C.UTF-8 \
    LANG=C.UTF-8

# Update base and install tools in logical groups
RUN apt-get update && apt-get install -y --no-install-recommends \
    # --- Layer 2 & 3 (Interface/Routing/ARP) ---
    iproute2 net-tools ethtool iputils-ping iputils-tracepath \
    traceroute mtr-tiny arping arp-scan iw wavemon \
    # --- Layer 4 (Transport/Sockets/Perf) ---
    iperf3 nuttcp fping netcat-openbsd socat ncat \
    # --- Layer 7 (Application/DNS/Web) ---
    dnsutils ldnsutils curl wget httpie openssl \
    # --- Inspection & Analysis (Capture) ---
    tcpdump tshark ngrep tcpreplay \
    # --- Security & Firewall ---
    nmap hping3 iptables nftables conntrack \
    # --- Monitoring (Real-time) ---
    iftop nethogs bmon vnstat procps \
    # --- Utilities & Data Handling ---
    jq rsync openssh-client whois ca-certificates less \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set default working directory
WORKDIR /work

# Default shell
CMD ["/bin/bash"]