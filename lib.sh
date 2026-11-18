#!/bin/bash

#Print information messages
log_info() {
    echo "[INFO] $1"
}

#Print error messages
log_error() {
    echo "[ERROR] $1" >&2
}

#Save an action in the log file
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

#Check if the directory exists
require_dir() {
    if [ -d "$1" ]; then
        return 0
    else
        log_error "Directory does not exist: $1"
        return 1
    fi
}
