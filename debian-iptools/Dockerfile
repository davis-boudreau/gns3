# Full IP/Networking Toolkit on Debian Slim
FROM debian:stable-slim

ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm-256color \
    LC_ALL=C.UTF-8 \
    LANG=C.UTF-8

# Update base and install tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Core networking + interfaces
    iproute2 \
    net-tools \
    ethtool \
    iputils-ping \
    iputils-tracepath \
    traceroute \
    mtr-tiny \
    arping \
    # DNS / name resolution
    dnsutils \ 
    ldnsutils \
    # HTTP / TLS / API
    curl \
    wget \
    httpie \
    openssl \
    # Bandwidth / throughput
    iperf3 \
    nuttcp \
    fping \
    # Sockets / ports
    netcat-openbsd \
    socat \
    ncat \
    # Capture & deep inspection
    tcpdump \
    tshark \
    ngrep \
    # Firewall / NAT / conntrack
    iptables \
    nftables \
    conntrack \
    # Monitoring
    iftop \
    nethogs \
    bmon \
    vnstat \
    # Security / scanning
    nmap \
    hping3 \
    arp-scan \
    # Wireless (optional; harmless on non-wifi hosts)
    iw \
    wavemon \
    # Utilities
    jq \
    rsync \
    openssh-client \
    whois \
    ca-certificates \
    procps \
    less \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Optional: create a non-root user for interactive use
# Uncomment if you want to avoid running as root by default.
# RUN useradd -m -s /bin/bash netops && \
#     echo "netops ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/netops
# USER netops
# WORKDIR /home/netops

# Default shell
CMD ["/bin/bash"]