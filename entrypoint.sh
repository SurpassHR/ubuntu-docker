#!/usr/bin/env bash
set -e

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
    mkdir -p /home/hr0530/mysql /home/hr0530/1panel /home/hr0530/apps
    chown -R mysql:mysql /home/hr0530/mysql
    echo "Storage directories initialized."

    # --- Application Deployment ---
    APP_DIR="/home/hr0530/apps/gemini-balance"
    if [ ! -d "$APP_DIR" ]; then
        echo "Cloning gemini-balance repository..."
        git clone https://github.com/SurpassHR/gemini-balance.git "$APP_DIR"
    else
        echo "Repository already exists. Skipping clone."
    fi

    echo "Installing Python dependencies for gemini-balance..."
    cd "$APP_DIR"
    python3.11 -m venv .venv
    source .venv/bin/activate
    pip install -r requirements.txt
    deactivate
    echo "Python dependencies installed."

    # --- Database Initialization ---
    # To initialize the database, we need mysqld running temporarily.
    # We start it directly and safely in the background.
    echo "Starting temporary MySQL server for initialization..."
    /usr/bin/mysqld_safe --user=mysql &
    MYSQLD_PID=$!

    echo "Waiting for MySQL service to be ready..."
    # Wait for the MySQL socket to become available.
    while ! mysqladmin ping -hlocalhost --silent; do
        echo "  ... waiting for mysqld to accept connections"
        sleep 2
    done
    echo "MySQL service is ready."

    echo "Initializing database from /tmp/init.sql..."
    mysql -u root < /tmp/init.sql
    echo "Database initialized."

    # Shut down the temporary MySQL server gracefully.
    echo "Shutting down temporary MySQL server..."
    mysqladmin -u root shutdown
    wait $MYSQLD_PID
    echo "Temporary MySQL server stopped."

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