#!/usr/bin/env sh

useradd -m -s /bin/bash $SSH_USER
echo "$SSH_USER:$SSH_PASSWORD" | chpasswd
usermod -aG sudo $SSH_USER
usermod -aG mysql $SSH_USER
echo "$SSH_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/init-users
echo 'PermitRootLogin no' > /etc/ssh/sshd_config.d/my_sshd.conf

mkdir -p /home/hr0530/boot
chmod 755 /home/hr0530/boot
curl https://raw.githubusercontent.com/SurpassHR/ubuntu-docker/refs/heads/essential_tools/supervisord.conf -o /home/hr0530/boot/supervisord.conf

# --- Prepare Persistent Volume Directories ---
# This section must run as root before supervisord starts.
# It ensures that all necessary subdirectories in the mounted volume exist
# and have the correct ownership, regardless of how the volume is mounted.

echo "Initializing persistent storage directories in /home/hr0530..."

# Create directories for all services that need persistent storage.
mkdir -p /home/hr0530/mysql
mkdir -p /home/hr0530/1panel

# Set ownership for the MySQL data directory.
# The 'mysql' user is created by the mysql-server package installation.
chown -R mysql:mysql /home/hr0530/mysql

# Make app directory and clone gemini-balance project
mkdir -p /home/hr0530/apps
GEMINI_BALANCE_DIR=/home/hr0530/apps/gemini-balance
if [ -d "${GEMINI_BALANCE_DIR}" ]; then
    cd ${GEMINI_BALANCE_DIR}
    git pull
else
    git clone https://github.com/SurpassHR/gemini-balance.git ${GEMINI_BALANCE_DIR}
fi
# Install gemini-balance dependencies
cd ${GEMINI_BALANCE_DIR} && python3 -m venv .venv
source ${GEMINI_BALANCE_DIR}/.venv/bin/activate
pip3 install -r requirements.txt
# Start gemini-balance
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

echo "Persistent storage directories initialized."


exec "$@"