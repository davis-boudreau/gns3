#!/bin/sh
set -eu

ORIGINAL_ENTRYPOINT="/usr/local/bin/docker-entrypoint.sh"
LOG_DIR="/var/log/postgresql"
LOG_FILE="${LOG_DIR}/postgresql.log"
PG_PID=""

cleanup() {
    if [ -n "${PG_PID}" ] && kill -0 "${PG_PID}" 2>/dev/null; then
        kill "${PG_PID}" 2>/dev/null || true
        wait "${PG_PID}" 2>/dev/null || true
    fi
}

trap cleanup INT TERM

run_console_mode() {
    mkdir -p "$LOG_DIR"

    "$ORIGINAL_ENTRYPOINT" postgres -c listen_addresses='*' >"$LOG_FILE" 2>&1 &
    PG_PID=$!

    echo
    echo "PostgreSQL started in background for GNS3 console mode."
    echo "Useful commands:"
    echo "  pg_isready -U ${POSTGRES_USER:-postgres} -d ${POSTGRES_DB:-postgres}"
    echo "  psql -U ${POSTGRES_USER:-postgres} -d ${POSTGRES_DB:-postgres}"
    echo "  tail -f $LOG_FILE"
    echo "  ip addr"
    echo "  ip route"
    echo "  ping <target>"
    echo

    if [ -t 0 ] && [ -t 1 ]; then
        /bin/sh || true
        echo
        echo "Console shell closed. PostgreSQL will keep running until the container stops."
        echo "Reconnect to the console or restart the node if you need another interactive shell."
        echo
    fi

    wait "$PG_PID"
}

if [ "${GNS3_SHELL_MODE:-false}" = "true" ] || [ "${1:-}" = "/bin/sh" ] || [ "${1:-}" = "sh" ]; then
    run_console_mode
fi

exec "$ORIGINAL_ENTRYPOINT" "$@" -c listen_addresses='*'
