#!/bin/bash
# PPA setup script for NetSnmp Enterprise

set -e

echo "Setting up PPA for NetSnmp Enterprise..."

# Check if required tools are installed
if ! command -v dput >/dev/null 2>&1; then
    echo "Installing dput..."
    sudo apt-get update
    sudo apt-get install -y dput devscripts debmake
fi

# Create source package
echo "Creating source package..."
cd packaging/deb

# Clean previous builds
rm -rf ../*.deb ../*.buildinfo ../*.changes ../*.dsc ../*.tar.*

# Build source package
debuild -S -sa

# Check if source package was created
if [[ -f ../netsnmp-enterprise_2.0.0-1_source.changes ]]; then
    echo "✅ Source package created successfully"
    echo ""
    echo "To upload to PPA:"
    echo "1. Create a PPA at https://launchpad.net"
    echo "2. Run: dput ppa:ky6/netsnmp-enterprise ../netsnmp-enterprise_2.0.0-1_source.changes"
    echo ""
    echo "Files created:"
    ls -la ../netsnmp-enterprise_2.0.0-1*
else
    echo "❌ Source package creation failed"
    exit 1
fi