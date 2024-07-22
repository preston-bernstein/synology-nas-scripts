#!/bin/bash

# Define log directories
LOG_DIRS=("/config/logs1" "/config/logs2" "/config/logs3")

# Function to delete old logs, keeping only the latest 30
cleanup_logs() {
    local log_dir="$1"

    # Check if the log directory exists
    if [ ! -d "$log_dir" ]; then
        echo "Log directory '$log_dir' not found."
        return
    fi

    # Find and delete all but the latest 30 log files
    find "$log_dir" -type f -name "remove_duplicates_*.log" -printf "%T@ %p\n" | sort -n | head -n -30 | cut -d' ' -f2- | xargs rm -f

    # Confirmation message
    echo "All but the latest 30 log files have been deleted from '$log_dir'."
}

# Iterate over each log directory and clean up old logs
for log_dir in "${LOG_DIRS[@]}"; do
    cleanup_logs "$log_dir"
done
