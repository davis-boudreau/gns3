# 1) Build locally
make build

# 2) Start the toolbox with compose
make up
ssh root@localhost -p 2222

# Local default SSH password
# iptools

# Or open an interactive shell directly
docker compose exec iptoolkit bash

# (Optional) Start iperf3 server and capture services
docker compose --profile perf up -d iperf3-server
docker compose --profile capture up -d tshark-capture

# 3) Tag and push to Docker Hub
make tag
make push

# 4) Tear down
make down
