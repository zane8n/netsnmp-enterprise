#!/bin/bash
# Snap package build script

set -e

cd "$(dirname "$0")"
ROOT_DIR="../../.."

echo "Building Snap package for NetSnmp Enterprise..."

# Check if required tools are installed
if ! command -v snapcraft >/dev/null 2>&1; then
    echo "Error: snapcraft not found. Install snapcraft package."
    exit 1
fi

# Clean previous builds
rm -rf *.snap
rm -rf prime/ stage/ parts/

# Build the main application
cd "$ROOT_DIR"
make clean
make

# Build the Snap package
cd packaging/snap
snapcraft

# Check if package was built successfully
if [[ -f netsnmp-enterprise_2.0.0_amd64.snap ]]; then
    echo ""
    echo "✅ Snap package built successfully:"
    echo "   netsnmp-enterprise_2.0.0_amd64.snap"
    
    # Test installation
    echo ""
    echo "Testing installation..."
    if sudo snap install --dangerous netsnmp-enterprise_2.0.0_amd64.snap; then
        echo "✅ Installation test successful"
        sudo snap remove netsnmp-enterprise
    else
        echo "❌ Installation test failed"
        exit 1
    fi
else
    echo "❌ Snap package build failed"
    exit 1
fi