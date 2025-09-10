#!/bin/bash
# Debug script for configuration issues

export TEST_MODE="true"
export CONFIG_DIR="/tmp/netsnmp-test/config"
export LOG_FILE="/tmp/netsnmp-test/debug.log"

mkdir -p "$CONFIG_DIR"
rm -rf "$CONFIG_DIR"/*

source "$(dirname "$0")/../core/utils.sh"
source "$(dirname "$0")/../core/logging.sh"
source "$(dirname "$0")/../core/config.sh"

echo "=== DEBUG CONFIGURATION ==="
echo "CONFIG_FILE: $CONFIG_FILE"

# Create test config
cat > "$CONFIG_FILE" << EOF
subnets="192.168.1.0/24"
communities="public"
ping_timeout="1"
snmp_timeout="2"
scan_workers="10"
cache_ttl="3600"
enable_logging="true"
EOF

echo "=== CONFIG FILE CONTENT ==="
cat "$CONFIG_FILE"
echo ""

echo "=== HEX DUMP ==="
od -c "$CONFIG_FILE"
echo ""

echo "=== LOADING CONFIG ==="
load_config

echo "=== LOADED CONFIG VALUES ==="
for key in "${!CONFIG[@]}"; do
    echo "$key: '${CONFIG[$key]}' (length: ${#CONFIG[$key]})"
    echo "   Hex: $(echo -n "${CONFIG[$key]}" | od -c)"
done

echo ""
echo "=== VALIDATION TEST ==="
if [[ "${CONFIG[ping_timeout]}" =~ ^[0-9]+$ ]]; then
    echo "✅ ping_timeout is numeric: ${CONFIG[ping_timeout]}"
else
    echo "❌ ping_timeout is NOT numeric: '${CONFIG[ping_timeout]}'"
    echo "   Hex: $(echo -n "${CONFIG[ping_timeout]}" | od -c)"
fi

rm -rf "/tmp/netsnmp-test"