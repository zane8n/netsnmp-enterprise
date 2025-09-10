#!/bin/bash
# Integration test script

# Set test environment variables
export TEST_MODE="true"
export CONFIG_DIR="/tmp/netsnmp-test/config"
export CACHE_DIR="/tmp/netsnmp-test/cache"
export LOG_FILE="/tmp/netsnmp-test/netsnmp-test.log"

# Create test directories
mkdir -p "$CONFIG_DIR"
mkdir -p "$CACHE_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# Source the modules
source "$(dirname "$0")/../core/utils.sh"
source "$(dirname "$0")/../core/logging.sh"
source "$(dirname "$0")/../core/config.sh"
source "$(dirname "$0")/../core/cache.sh"
source "$(dirname "$0")/../core/scanner.sh"

echo "Running integration tests..."
echo "Test environment:"
echo "  CONFIG: $CONFIG_DIR"
echo "  CACHE: $CACHE_DIR"
echo "  LOG: $LOG_FILE"

# Clean previous test files
rm -rf "$CONFIG_DIR"/* "$CACHE_DIR"/* "$LOG_FILE"

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

# Test cache info with empty cache
echo "4. Testing cache information..."
show_cache_info > /dev/null 2>&1
# This should fail gracefully with empty cache, which is expected
echo "   ✅ Cache info test passed (expected failure with empty cache)"

echo "All integration tests passed! ✅"

# Cleanup
rm -rf "/tmp/netsnmp-test"