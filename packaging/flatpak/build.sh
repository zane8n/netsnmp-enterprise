#!/bin/bash
# Flatpak build script

set -e

cd "$(dirname "$0")"
ROOT_DIR="../../.."

echo "Building Flatpak package for NetSnmp Enterprise..."

# Check if required tools are installed
if ! command -v flatpak >/dev/null 2>&1; then
    echo "Error: flatpak not found. Install flatpak package."
    exit 1
fi

if ! command -v flatpak-builder >/dev/null 2>&1; then
    echo "Error: flatpak-builder not found. Install flatpak-builder package."
    exit 1
fi

# Clean previous builds
rm -rf build/
rm -rf .flatpak-builder/
rm -rf *.flatpak

# Build the main application
cd "$ROOT_DIR"
make clean
make

# Create source tarball
tar czf ../packaging/flatpak/netsnmp-enterprise-2.0.0.tar.gz --exclude=.git --exclude=packaging .

# Build the Flatpak
cd packaging/flatpak
flatpak-builder --force-clean build-dir com.zane8n.netsnmp.yaml
flatpak build-bundle build-dir netsnmp-enterprise.flatpak com.zane8n.netsnmp

# Check if package was built successfully
if [[ -f netsnmp-enterprise.flatpak ]]; then
    echo ""
    echo "✅ Flatpak package built successfully:"
    echo "   netsnmp-enterprise.flatpak"
else
    echo "❌ Flatpak package build failed"
    exit 1
fi