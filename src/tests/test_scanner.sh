#!/bin/bash
# Test script for scanner functionality

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
source "$(dirname "$0")/../core/scanner.sh"

echo "Testing scanner functionality..."

# Clean previous test files
rm -rf "$CONFIG_DIR"/* "$CACHE_DIR"/* "$LOG_FILE"

# Initialize config
init_config

# Test IP generation
echo "1. Testing IP generation..."
ips=$(generate_ip_list "192.168.1.1-3")
if [[ $(echo "$ips" | wc -l) -eq 3 ]]; then
    echo "   ✅ IP generation test passed"
    echo "   Generated IPs:"
    echo "$ips" | sed 's/^/     /'
else
    echo "   ❌ IP generation test failed"
    echo "   Expected 3 IPs, got: $(echo "$ips" | wc -l)"
    exit 1
fi

# Test CIDR IP generation
echo "2. Testing CIDR IP generation..."
ips=$(generate_ip_list "192.168.0.0/24")  # Should generate 192.168.0.1-254
if [[ $(echo "$ips" | wc -l) -eq 2 ]]; then
    echo "   ✅ CIDR IP generation test passed"
else
    echo "   ❌ CIDR IP generation test failed"
    exit 1
fi

# Test network validation
echo "3. Testing network validation..."
if validate_ip "192.168.1.1"; then
    echo "   ✅ IP validation test passed"
else
    echo "   ❌ IP validation test failed"
    exit 1
fi

# Test invalid IP validation
echo "4. Testing invalid IP validation..."
if ! validate_ip "invalid.ip.address"; then
    echo "   ✅ Invalid IP validation test passed"
else
    echo "   ❌ Invalid IP validation test failed"
    exit 1
fi

echo "Scanner tests completed! ✅"

# Cleanup
rm -rf "/tmp/netsnmp-test"