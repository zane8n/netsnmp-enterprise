#!/bin/bash
# Arch Linux package build script

set -e

cd "$(dirname "$0")"
ROOT_DIR="../../.."

echo "Building Arch Linux package for NetSnmp Enterprise..."

# Check if required tools are installed
if ! command -v makepkg >/dev/null 2>&1; then
    echo "Error: makepkg not found. Install base-devel package."
    exit 1
fi

# Clean previous builds
rm -rf *.pkg.tar.*
rm -rf src/ pkg/

# Build the main application
cd "$ROOT_DIR"
make clean
make

# Create source tarball
tar czf ../packaging/arch/netsnmp-enterprise-2.0.0.tar.gz --exclude=.git --exclude=packaging .

# Build the package
cd packaging/arch
makepkg -si

# Check if package was built successfully
if [[ -f netsnmp-enterprise-2.0.0-1-any.pkg.tar.zst ]]; then
    echo ""
    echo "✅ Arch Linux package built successfully:"
    echo "   netsnmp-enterprise-2.0.0-1-any.pkg.tar.zst"
    
    # Show package info
    echo ""
    echo "Package information:"
    tar -tf netsnmp-enterprise-2.0.0-1-any.pkg.tar.zst | head -10
else
    echo "❌ Arch Linux package build failed"
    exit 1
fi