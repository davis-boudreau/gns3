# 1) Build locally
make build

# 2) Start the toolbox with compose
make compose-up
docker compose exec iptoolkit bash

# (Optional) Start iperf3 server and capture services
docker compose --profile perf up -d iperf3-server
docker compose --profile capture up -d tshark-capture

# 3) Tag and push to your registry
REGISTRY=ghcr.io/your-org make tag
REGISTRY=ghcr.io/your-org make push    # or use make buildx for multi-arch + push

# 4) Tear down
make compose-down