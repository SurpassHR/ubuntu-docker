#!/bin/bash
#
# This script is managed by Supervisord to control the 1Panel service.
# It handles the initial setup on the first run and then starts the service.
#

set -e

PANEL_BASE_DIR="/home/hr0530/1panel"
DB_FILE="${PANEL_BASE_DIR}/db/1Panel.db"
UPDATE_SCRIPT_PATH="${PANEL_BASE_DIR}/update_app_version.sh"

# --- First Run Initialization ---
# Check if the database file exists to determine if this is the first run.
if [ ! -f "$DB_FILE" ]; then
    echo "--- First time running 1Panel, performing initial setup ---"
    
    # Start 1panel in the background to let it create the database and other assets.
    /usr/local/bin/1panel &
    PANEL_PID=$!
    
    # Wait for the database file to be created, with a timeout.
    echo "Waiting for database creation at ${DB_FILE}..."
    counter=0
    while [ ! -f "$DB_FILE" ]; do
        sleep 1
        counter=$((counter+1))
        if [ "$counter" -ge 20 ]; then
            echo "[ERROR] 1Panel database not created after 20 seconds. Aborting."
            kill $PANEL_PID
            exit 1
        fi
    done
    
    echo "Database created successfully."
    
    # Gracefully stop the temporary 1Panel process.
    echo "Stopping temporary 1Panel process (PID: $PANEL_PID)..."
    kill $PANEL_PID
    wait $PANEL_PID 2>/dev/null
    
    # The installation process moves update_app_version.sh to /opt/1panel.
    # We run it here after the initial database is created.
    if [ -f "$UPDATE_SCRIPT_PATH" ]; then
        echo "Running post-install version update..."
        bash "$UPDATE_SCRIPT_PATH"
    fi
    
    echo "--- 1Panel initial setup complete ---"
fi

# --- Start 1Panel Service ---
echo "Starting 1Panel service in the foreground..."
# Use exec to make 1Panel the main process, allowing Supervisor to manage it correctly.
exec /usr/local/bin/1panel