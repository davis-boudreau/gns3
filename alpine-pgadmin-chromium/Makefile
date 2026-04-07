VERSION ?= latest
IMAGE_NAME ?= alpine-pgadmin-chromium
HUB_IMAGE ?= davisboudreau/alpine-pgadmin-chromium

.PHONY: build up down logs shell tag push publish

build:
	docker build -t $(IMAGE_NAME):$(VERSION) .

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f

shell:
	docker exec -it $(IMAGE_NAME) /bin/bash

tag:
	docker tag $(IMAGE_NAME):$(VERSION) $(HUB_IMAGE):$(VERSION)

push:
	docker push $(HUB_IMAGE):$(VERSION)

publish: build tag push
