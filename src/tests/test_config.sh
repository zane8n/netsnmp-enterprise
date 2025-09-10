#!/bin/bash
# Test script for configuration management
# Set test environment variables
export TEST_MODE="true"
export CONFIG_DIR="/tmp/netsnmp-test/config"
export CACHE_DIR="/tmp/netsnmp-test/cache"
export LOG_FILE="/tmp/netsnmp-test/netsnmp-test.log"

# Create test directories
mkdir -p "$CONFIG_DIR"
mkdir -p "$CACHE_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# Source the modules with proper path
source "$(dirname "$0")/../core/utils.sh"
source "$(dirname "$0")/../core/logging.sh"
source "$(dirname "$0")/../core/config.sh"

echo "Testing configuration management..."
echo "Test directories:"
echo "  CONFIG: $CONFIG_DIR"
echo "  CACHE: $CACHE_DIR"
echo "  LOG: $LOG_FILE"

# Clean previous test files
rm -rf "$CONFIG_DIR"/* "$CACHE_DIR"/* "$LOG_FILE"


# Test config creation
echo "1. Testing configuration creation..."
init_config
if [[ -f "$CONFIG_FILE" ]]; then
    echo "   ✅ Config file created successfully: $CONFIG_FILE"
else
    echo "   ❌ Config file creation failed"
    exit 1
fi

# Test config loading
echo "2. Testing configuration loading..."
load_config
if [[ -n "${CONFIG[subnets]}" ]]; then
    echo "   ✅ Config loaded successfully"
    echo "   ✅ Subnets: ${CONFIG[subnets]}"
else
    echo "   ❌ Config loading failed"
    exit 1
fi

# Test config validation - check if ping_timeout is numeric
echo "3. Testing configuration validation..."
if [[ -n "${CONFIG[ping_timeout]}" ]] && [[ "${CONFIG[ping_timeout]}" =~ ^[0-9]+$ ]]; then
    echo "   ✅ Config validation passed"
    echo "   ✅ Ping timeout: ${CONFIG[ping_timeout]}"
else
    echo "   ❌ Config validation failed"
    echo "   ❌ Ping timeout value: '${CONFIG[ping_timeout]}'"
    echo "   ❌ Expected numeric value, got: $(echo "${CONFIG[ping_timeout]}" | od -c)"
    exit 1
fi

# Test config saving
echo "4. Testing configuration saving..."
CONFIG[subnets]="192.168.1.0/24 10.0.0.0/24"
save_config
if [[ -f "$CONFIG_FILE" ]] && grep -q "192.168.1.0/24" "$CONFIG_FILE"; then
    echo "   ✅ Config saving passed"
else
    echo "   ❌ Config saving failed"
    exit 1
fi

echo "All configuration tests passed! ✅"

# Cleanup
rm -rf "/tmp/netsnmp-test"