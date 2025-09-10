#!/bin/bash
# Configuration management for NetSnmp Enterprise

# Set test environment if TEST_MODE is set
if [[ "$TEST_MODE" == "true" ]]; then
    CONFIG_DIR="${CONFIG_DIR:-/tmp/netsnmp-test/config}"
    CACHE_DIR="${CACHE_DIR:-/tmp/netsnmp-test/cache}"
    LOG_FILE="${LOG_FILE:-/tmp/netsnmp-test/netsnmp-test.log}"
else
    # Original logic for production
    if [[ $EUID -eq 0 ]]; then
        CONFIG_DIR="/etc/netsnmp"
        CACHE_DIR="/var/cache/netsnmp"
        LOG_FILE="/var/log/netsnmp.log"
    else
        CONFIG_DIR="${HOME}/.config/netsnmp"
        CACHE_DIR="${HOME}/.cache/netsnmp"
        LOG_FILE="${HOME}/.cache/netsnmp.log"
    fi
fi

CACHE_FILE="${CACHE_DIR}/hosts.cache"
CONFIG_FILE="${CONFIG_DIR}/netsnmp.conf"

# Initialize configuration
init_config() {
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$CACHE_DIR"
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # Create default config if it doesn't exist
    if [[ ! -f "$CONFIG_FILE" ]] || [[ ! -s "$CONFIG_FILE" ]]; then
        create_default_config
    fi
    
    # Load configuration
    load_config
}

# Create default configuration
create_default_config() {
    cat > "$CONFIG_FILE" << EOF
# NetSnmp Enterprise configuration
# Generated on $(date)

# Networks to scan (space separated)
subnets="192.168.1.0/24 10.0.0.0/24"

# SNMP communities to try
communities="public private"

# Ping timeout in seconds
ping_timeout="1"

# SNMP timeout in seconds
snmp_timeout="2"

# Number of parallel workers
scan_workers="10"

# Cache TTL in seconds
cache_ttl="3600"

# Enable logging
enable_logging="true"
EOF
    
    # Set permissions if root
    if [[ $EUID -eq 0 ]]; then
        chmod 644 "$CONFIG_FILE" 2>/dev/null
    fi
    
    log "Created default configuration: $CONFIG_FILE"
}

# Load configuration from file
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        # Clear existing config
        for key in "${!CONFIG[@]}"; do
            CONFIG["$key"]=""
        done
        
        # Read config file
        while IFS='=' read -r key value; do
            # Skip comments and empty lines
            [[ $key =~ ^# ]] || [[ -z $key ]] && continue
            
            # Clean up key and value
            key=$(echo "$key" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
            value=$(echo "$value" | sed -e 's/^[[:space:]]*//; s/[[:space:]]*$//' -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
            
            # Store in config array
            CONFIG["$key"]="$value"
        done < "$CONFIG_FILE"
        
        log_debug "Configuration loaded from: $CONFIG_FILE"
        return 0
    else
        log_error "Configuration file not found: $CONFIG_FILE"
        return 1
    fi
}

# Save configuration to file
save_config() {
    cat > "$CONFIG_FILE" << EOF
# NetSnmp Enterprise configuration
# Generated on $(date)

subnets="${CONFIG[subnets]}"
communities="${CONFIG[communities]}"
ping_timeout="${CONFIG[ping_timeout]}"
snmp_timeout="${CONFIG[snmp_timeout]}"
scan_workers="${CONFIG[scan_workers]}"
cache_ttl="${CONFIG[cache_ttl]}"
enable_logging="${CONFIG[enable_logging]}"
EOF
    
    log "Configuration saved: $CONFIG_FILE"
}

# Show current configuration
show_config() {
    echo "Current Configuration:"
    echo "Config File: $CONFIG_FILE"
    echo ""
    for key in "${!CONFIG[@]}"; do
        printf "  %-15s: %s\n" "$key" "${CONFIG[$key]}"
    done
    echo ""
    echo "Edit configuration: nano $CONFIG_FILE"
}

# Run configuration wizard
run_config_wizard() {
    echo "╔══════════════════════════════════════════════════╗"
    echo "║             NetSnmp Configuration Wizard         ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo ""
    
    echo "Enter networks to scan (space separated):"
    echo "Examples: 192.168.1.0/24 10.0.0.1-100 172.16.1.50"
    read -p "Networks: " user_networks
    CONFIG[subnets]="${user_networks:-192.168.1.0/24 10.0.0.0/24}"
    
    echo ""
    echo "Enter SNMP communities to try (space separated):"
    echo "Example: public private read-only"
    read -p "Communities: " user_communities
    CONFIG[communities]="${user_communities:-public private}"
    
    save_config
    
    echo ""
    echo "✓ Configuration saved to: $CONFIG_FILE"
    echo "✓ Use 'netsnmp --update' to start scanning"
}