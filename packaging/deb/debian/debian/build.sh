#!/bin/bash
# Debian package build script

set -e

echo "Building Debian package for NetSnmp Enterprise..."

# Check if required tools are installed
if ! command -v dpkg-buildpackage >/dev/null 2>&1; then
    echo "Error: dpkg-buildpackage not found. Install build-essential package."
    exit 1
fi

if ! command -v dh >/dev/null 2>&1; then
    echo "Error: dh not found. Install debhelper package."
    exit 1
fi


# Clean previous builds (but don't use make clean)
rm -rf ../*.deb ../*.buildinfo ../*.changes ../*.dsc
rm -rf debian/netsnmp-enterprise debian/.debhelper debian/files debian/debhelper-build-stamp

# Build the Debian package directly (dh_auto_build in rules will handle the build)
dpkg-buildpackage -uc -us -b

# Check if package was built successfully
if [[ -f ../netsnmp-enterprise_2.0.0_all.deb ]]; then
    echo ""
    echo "✅ Debian package built successfully:"
    echo "   ../netsnmp-enterprise_2.0.0_all.deb"
    
    # Show package info
    echo ""
    echo "Package information:"
    dpkg-deb -I ../netsnmp-enterprise_2.0.0_all.deb
    
    # Test installation
    echo ""
    echo "Testing installation..."
    if sudo dpkg -i ../netsnmp-enterprise_2.0.0_all.deb; then
        echo "✅ Installation test successful"
        sudo dpkg -r netsnmp-enterprise
    else
        echo "❌ Installation test failed"
        exit 1
    fi
else
    echo "❌ Package build failed"
    exit 1
fi