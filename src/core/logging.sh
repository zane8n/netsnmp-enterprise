#!/bin/bash
# Logging functions for NetSnmp Enterprise

# Initialize logging
init_logging() {
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # Only set permissions if we're root
    if [[ $EUID -eq 0 ]]; then
        touch "$LOG_FILE" 2>/dev/null && chmod 644 "$LOG_FILE" 2>/dev/null
    else
        touch "$LOG_FILE" 2>/dev/null
    fi
}

# Log message with timestamp
log() {
    local message="[$(get_timestamp)] $*"
    echo "$message" >&2
    
    # Only log to file if enabled and we have permission
    if [[ "${CONFIG[enable_logging]}" == "true" ]]; then
        echo "$message" >> "$LOG_FILE" 2>/dev/null || true
    fi
}

# Log error message
log_error() {
    log "[ERROR] $*"
}

# Log success message
log_success() {
    log "[SUCCESS] $*"
}

# Log debug message
log_debug() {
    if [[ "$VERBOSE" == "true" ]] || [[ "$DEBUG" == "true" ]]; then
        local timestamp=$(date '+%H:%M:%S')
        echo "[DEBUG $timestamp] $*" >&2
    fi
}

# Log warning message
log_warning() {
    log "[WARNING] $*"
}