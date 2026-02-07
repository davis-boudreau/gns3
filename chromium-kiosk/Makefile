# Usage: make help
help:
    @echo "Targets:"
    @echo "  make dev        - Build locally and run (profile: dev)"
    @echo "  make hub        - Pull from Docker Hub and run (profile: hub)"
    @echo "  make down       - Stop and remove container (keeps named volume)"
    @echo "  make restart   - Restart running services"
    @echo "  make logs       - Follow logs"
    @echo "  make ps         - Show container status"
    @echo "  make shell      - Shell into the running container"
    @echo "  make ports      - Show published ports"
    @echo "  make clean      - Stop containers and remove orphans"
    @echo "  make reset      - Stop containers and delete named volumes"
    @echo "  make build      - Build local image (VERSION=latest by default)"
    @echo "  make tag        - Tag local image as Docker Hub image"
    @echo "  make push       - Push tagged image to Docker Hub"
    @echo "  make publish    - Build, tag, and push image"
    @echo ""
    @echo "Usage CI/CD:"
    @echo "  make dev"
    @echo "  make hub VERSION=1.0.0"
    @echo "  make publish VERSION=1.0.0"

# Usage: make dev
dev:
    $(COMPOSE) --profile dev up -d --build

# Usage: make hub
hub:
    docker pull $(HUB_IMAGE):$(VERSION)
    $(COMPOSE) --profile hub up -d

# Usage: make down
down:
    $(COMPOSE) down

# Usage: make restart
restart:
    $(COMPOSE) restart

# Usage: make logs
logs:
    $(COMPOSE) logs -f --tail=200

# Usage: make ps
ps:
    $(COMPOSE) ps

# Usage: make shell
shell:
    docker exec -it $(CONTAINER) sh

# Usage: make ports
ports:
    @docker port $(CONTAINER) || true

# Usage: make clean
clean:
    $(COMPOSE) down --remove-orphans

# Usage: make reset
reset:
    $(COMPOSE) down -v --remove-orphans

# Usage: make build VERSION=1.0.0
build:
    docker build -t alpine-chromium-kiosk:$(VERSION) .

# Usage: make tag VERSION=1.0.0
tag:
    docker tag alpine-chromium-kiosk:$(VERSION) $(HUB_IMAGE):$(VERSION)

# Usage: make push VERSION=1.0.0
push:
    docker push $(HUB_IMAGE):$(VERSION)

# Usage: make publish VERSION=1.0.0
publish: build tag push
    @echo "Published $(HUB_IMAGE):$(VERSION)"