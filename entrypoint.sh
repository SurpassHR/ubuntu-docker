#!/usr/bin/env bash
# set -e

# --- Initialization Lock ---
# Use a lock file to ensure initialization runs only once.
INIT_LOCK_FILE="/home/hr0530/.initialized"

if [ ! -f "$INIT_LOCK_FILE" ]; then
    echo "--- First time container startup: Initializing... ---"

    # --- User and SSH Setup ---
    echo "Setting up user '$SSH_USER'..."
    useradd -m -s /bin/bash "$SSH_USER"
    echo "$SSH_USER:$SSH_PASSWORD" | chpasswd
    usermod -aG sudo "$SSH_USER"
    usermod -aG mysql "$SSH_USER"
    echo "$SSH_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/init-users
    # Secure SSH configuration
    echo 'PermitRootLogin no' > /etc/ssh/sshd_config.d/my_sshd.conf
    echo "User setup complete."

    # --- Persistent Volume and App Setup ---
    echo "Initializing persistent storage directories in /home/hr0530..."
    DATA_DIR="/home/hr0530/data"
    APP_DIR="/home/hr0530/apps"
    # 等待 DATA_DIR 和 APP_DIR 目录创建
    while [ ! -d ${DATA_DIR} ] || [ ! -d ${APP_DIR} ]; do
        echo "Waiting for directories to be created..."
        mkdir -p /home/hr0530/1panel ${APP_DIR} ${DATA_DIR}
        sleep 1
    done
    echo "Storage directories initialized."

    # --- Application Deployment ---
    GEMINI_BALANCE="${APP_DIR}/gemini-balance"
    if [ ! -d "${GEMINI_BALANCE}" ]; then
        echo "Downloading gemini-balance repository..."
        curl https://codeload.github.com/SurpassHR/gemini-balance/zip/refs/heads/main > ${DATA_DIR}/gemini-balance.zip && \
        # 正常日志重定向到 /dev/null，错误日志展示在终端
        unzip ${DATA_DIR}/gemini-balance.zip -d "${APP_DIR}" && mv "${APP_DIR}/gemini-balance-main" "${GEMINI_BALANCE}" 2>&1 > /dev/null && \
        rm -rf ${DATA_DIR}/gemini-balance.zip
    else
        echo "Repository already exists. Skipping download."
    fi

    # --- Create Lock File ---
    touch "$INIT_LOCK_FILE"
    echo "--- Initialization complete. ---"
else
    echo "--- Container already initialized. Skipping setup. ---"
fi

# --- Start Services ---
# The main CMD will now take over and run supervisord in the foreground.
echo "Handing over to supervisord..."
exec "$@"