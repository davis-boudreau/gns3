# Configuration
export HUB_IMAGE := davisboudreau/alpine-chromium-kiosk
export VERSION ?= latest
COMPOSE := docker compose

.PHONY: dev hub down restart logs ps shell ports build tag push publish reset

# Run local build
dev:
	$(COMPOSE) --profile dev up -d --build

# Run from Docker Hub
hub:
	docker pull $(HUB_IMAGE):$(VERSION)
	$(COMPOSE) --profile hub up -d

# Generic Lifecycle
down:
	$(COMPOSE) --profile dev --profile hub down

restart:
	$(COMPOSE) restart

logs:
	$(COMPOSE) logs -f --tail=200

ps:
	$(COMPOSE) ps

shell:
	@cid=$$(docker ps -q --filter "label=com.docker.compose.service"); \
	if [ -z "$$cid" ]; then echo "No kiosk container running."; exit 1; fi; \
	docker exec -it $$cid bash

# Image Management
build:
	docker build -t alpine-chromium-kiosk:$(VERSION) .

tag:
	docker tag alpine-chromium-kiosk:$(VERSION) $(HUB_IMAGE):$(VERSION)

push:
	docker push $(HUB_IMAGE):$(VERSION)

publish: build tag push
	@echo "Published $(HUB_IMAGE):$(VERSION)"

reset:
	$(COMPOSE) --profile dev --profile hub down -v --remove-orphans