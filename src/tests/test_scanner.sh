#!/bin/bash
# Test script for scanner functionality

source ../core/utils.sh
source ../core/logging.sh
source ../core/config.sh
source ../core/scanner.sh

echo "Testing scanner functionality..."

# Test IP generation
echo "1. Testing IP generation..."
ips=$(generate_ip_list "192.168.1.1-3")
if [[ $(echo "$ips" | wc -l) -eq 3 ]]; then
    echo "   ✅ IP generation test passed"
else
    echo "   ❌ IP generation test failed"
    exit 1
fi

# Test SNMP function (mock test)
echo "2. Testing SNMP function (mock)..."
if command -v snmpget >/dev/null 2>&1; then
    echo "   ✅ SNMP tools available"
else
    echo "   ⚠️  SNMP tools not available (some tests skipped)"
fi

# Test network validation
echo "3. Testing network validation..."
if validate_ip "192.168.1.1"; then
    echo "   ✅ IP validation test passed"
else
    echo "   ❌ IP validation test failed"
    exit 1
fi

echo "Scanner tests completed! ✅"