FROM postgres:16-alpine

RUN apk add --no-cache \
    bash \
    bind-tools \
    busybox-extras \
    curl \
    iproute2 \
    iputils \
    less \
    netcat-openbsd \
    procps

COPY gns3-entrypoint.sh /usr/local/bin/gns3-entrypoint.sh
RUN chmod +x /usr/local/bin/gns3-entrypoint.sh

ENV TZ=UTC

ENTRYPOINT ["/usr/local/bin/gns3-entrypoint.sh"]

EXPOSE 5432
