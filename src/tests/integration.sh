#!/bin/bash
# Integration test script

source ../core/utils.sh
source ../core/logging.sh
source ../core/config.sh
source ../core/cache.sh
source ../core/scanner.sh

echo "Running integration tests..."

# Test full initialization
echo "1. Testing full initialization..."
init_config
init_logging

if [[ -f "$CONFIG_FILE" ]]; then
    echo "   ✅ Initialization test passed"
else
    echo "   ❌ Initialization test failed"
    exit 1
fi

# Test cache functionality
echo "2. Testing cache functionality..."
clear_cache
if [[ ! -f "$CACHE_FILE" ]]; then
    echo "   ✅ Cache clearance test passed"
else
    echo "   ❌ Cache clearance test failed"
    exit 1
fi

# Test config show
echo "3. Testing configuration display..."
show_config > /dev/null
if [[ $? -eq 0 ]]; then
    echo "   ✅ Config display test passed"
else
    echo "   ❌ Config display test failed"
    exit 1
fi

echo "All integration tests passed! ✅"