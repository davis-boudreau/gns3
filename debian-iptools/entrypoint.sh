#!/bin/sh
set -eu

SSH_PORT="${SSH_PORT:-2222}"
SSH_USER="${SSH_USER:-root}"
SSH_PASSWORD="${SSH_PASSWORD:-iptools}"
START_SSH="${START_SSH:-true}"

if [ "$START_SSH" = "true" ]; then
    mkdir -p /run/sshd

    if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
        ssh-keygen -A >/dev/null 2>&1
    fi

    if [ "$SSH_USER" = "root" ]; then
        echo "root:${SSH_PASSWORD}" | chpasswd
    else
        if ! id "$SSH_USER" >/dev/null 2>&1; then
            useradd -m -s /bin/bash "$SSH_USER"
        fi
        echo "${SSH_USER}:${SSH_PASSWORD}" | chpasswd
    fi

    cat >/etc/ssh/sshd_config.d/99-iptools.conf <<EOF
Port ${SSH_PORT}
PasswordAuthentication yes
PermitRootLogin yes
UsePAM no
X11Forwarding no
PrintMotd no
EOF

    /usr/sbin/sshd
fi

exec "$@"
