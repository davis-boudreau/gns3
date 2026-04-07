VERSION ?= latest
IMAGE_NAME ?= alpine-postgres
HUB_IMAGE ?= davisboudreau/alpine-postgres

.PHONY: build up down logs shell psql tag push publish

build:
	docker build -t $(IMAGE_NAME):$(VERSION) .

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f

shell:
	docker exec -it $(IMAGE_NAME) sh

psql:
	docker exec -it $(IMAGE_NAME) psql -U $${POSTGRES_USER:-postgres} -d $${POSTGRES_DB:-postgres}

tag:
	docker tag $(IMAGE_NAME):$(VERSION) $(HUB_IMAGE):$(VERSION)

push:
	docker push $(HUB_IMAGE):$(VERSION)

publish: build tag push
