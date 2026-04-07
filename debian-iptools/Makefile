-include .env

# Local build variables
IMAGE_NAME ?= iptools
IMAGE_TAG  ?= debian-slim
PROJECT    ?= iptoolkit

# Publishing variables
export HUB_IMAGE := davisboudreau/debian-iptools
export VERSION   ?= latest

.PHONY: build run shell up up-all compose-up compose-down down logs clean help tag push publish

help:
	@echo "Usage: make [target]"
	@echo "  build   Build local image ($(IMAGE_NAME):$(IMAGE_TAG))"
	@echo "  publish Build, tag, and push to $(HUB_IMAGE):$(VERSION)"
	@echo "  up      Start toolkit (default profile)"

build:
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .

# Tag the local build with the Hub name and version
tag:
	docker tag $(IMAGE_NAME):$(IMAGE_TAG) $(HUB_IMAGE):$(VERSION)

push:
	docker push $(HUB_IMAGE):$(VERSION)

# The full publishing pipeline
publish: build tag push
	@echo "Successfully published $(HUB_IMAGE):$(VERSION)"

# --- Execution Targets ---
up:
	docker compose --profile default up -d

up-all:
	docker compose --profile default --profile perf --profile capture up -d

compose-up: up

compose-down: down

shell:
	docker exec -it $(PROJECT) /bin/bash

down:
	docker compose --profile default --profile perf --profile capture down

clean:
	docker rmi $(IMAGE_NAME):$(IMAGE_TAG) || true
	docker rmi $(HUB_IMAGE):$(VERSION) || true
