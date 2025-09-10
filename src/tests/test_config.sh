#!/bin/bash
# Test script for configuration management

source ../core/utils.sh
source ../core/logging.sh
source ../core/config.sh

echo "Testing configuration management..."

# Test config creation
echo "1. Testing configuration creation..."
init_config
if [[ -f "$CONFIG_FILE" ]]; then
    echo "   ✅ Config file created successfully"
else
    echo "   ❌ Config file creation failed"
    exit 1
fi

# Test config loading
echo "2. Testing configuration loading..."
load_config
if [[ -n "${CONFIG[subnets]}" ]]; then
    echo "   ✅ Config loaded successfully"
else
    echo "   ❌ Config loading failed"
    exit 1
fi

# Test config validation
echo "3. Testing configuration validation..."
if [[ -n "${CONFIG[ping_timeout]}" ]] && [[ "${CONFIG[ping_timeout]}" =~ ^[0-9]+$ ]]; then
    echo "   ✅ Config validation passed"
else
    echo "   ❌ Config validation failed"
    exit 1
fi

echo "All configuration tests passed! ✅"