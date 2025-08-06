#!/usr/bin/env sh

useradd -m -s /bin/bash $SSH_USER
echo "$SSH_USER:$SSH_PASSWORD" | chpasswd
usermod -aG sudo $SSH_USER
echo "$SSH_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/init-users
echo 'PermitRootLogin no' > /etc/ssh/sshd_config.d/my_sshd.conf

mkdir -p /home/hr0530/boot
chmod 755 /home/hr0530/boot
curl https://raw.githubusercontent.com/SurpassHR/ubuntu-docker/refs/heads/essential_tools/supervisord.conf -o /home/hr0530/boot/supervisord.conf

exec "$@"