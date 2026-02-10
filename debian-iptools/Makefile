# ========= Configuration =========
IMAGE_NAME ?= iptoolkit
IMAGE_TAG  ?= debian-slim
PLATFORM   ?= linux/amd64
REGISTRY   ?=			 # e.g., ghcr.io/your-org OR docker.io/youruser
PUSH_NAME  ?= $(if $(REGISTRY),$(REGISTRY)/$(IMAGE_NAME),$(IMAGE_NAME))

# Multi-arch (optional): set to "linux/amd64,linux/arm64" and use buildx targets
PLATFORMS  ?= $(PLATFORM)

# Compose project name
PROJECT	   ?= iptoolkit

# ========= Phony targets =========
.PHONY: all build buildx run shell stop logs push tag latest clean prune compose-up compose-down

all: build

# Build using local docker (single arch)
build:
	docker build --pull -t $(IMAGE_NAME):$(IMAGE_TAG) .

# Build multi-arch with buildx (requires: docker buildx create/use)
buildx:
	docker buildx build \
	--platform $(PLATFORMS) \
	-t $(PUSH_NAME):$(IMAGE_TAG) \
	--pull \
	--push \
	.
# Tag image for registry (no push)
tag:
	docker tag $(IMAGE_NAME):$(IMAGE_TAG) $(PUSH_NAME):$(IMAGE_TAG)

# Push (single-arch): make sure you've run `make tag` first or use same local name/registry
push:
	docker push $(PUSH_NAME):$(IMAGE_TAG)

# Optional convenience: also tag as latest and push
latest:
	docker tag $(IMAGE_NAME):$(IMAGE_TAG) $(PUSH_NAME):latest
	docker push $(PUSH_NAME):latest

# Run with sensible defaults (host net + caps)
run:
	docker run -it --rm \
	--name $(PROJECT) \
	--net=host \
	--cap-add=NET_ADMIN --cap-add=NET_RAW \
	-v vnstat-db:/var/lib/vnstat \
	-v $(PWD)/work:/work \
	$(IMAGE_NAME):$(IMAGE_TAG) /bin/bash

# Quick interactive shell into a currently running container
shell:
	docker exec -it $(PROJECT) /bin/bash || \
	docker compose exec iptoolkit /bin/bash

# Compose: up/down (default profile)
compose-up:
	docker compose --project-name $(PROJECT) up -d

compose-down:
	docker compose --project-name $(PROJECT) down

# Logs (follow)
logs:
	docker compose --project-name $(PROJECT) logs -f

# Stop & clean local image/container
stop:
	-docker stop $(PROJECT) 2>/dev/null || true
	-docker rm $(PROJECT) 2>/dev/null || true

clean:
	-docker rmi $(IMAGE_NAME):$(IMAGE_TAG) 2>/dev/null || true
	-docker rmi $(PUSH_NAME):$(IMAGE_TAG) 2>/dev/null || true

# Danger zone: prune dangling images/volumes
prune:
	docker system prune -f