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



# Create debian directory structure if it doesn't exist
if [ ! -d "debian" ]; then
    mkdir -p debian
fi


# Fix the changelog date (replace $(date -R) with actual date)
sed -i "s/\$(date -R)/$(date -R)/g" debian/changelog

chmod +x debian/rules

# Clean previous builds (but preserve debian/ directory)
rm -rf ../*.deb ../*.buildinfo ../*.changes ../*.dsc
rm -rf debian/netsnmp-enterprise debian/.debhelper debian/files debian/debhelper-build-stamp

# Build the Debian package
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
    

    # Test installation - handle CI environments without sudo
    echo ""
    echo "Testing package..."
    if command -v sudo >/dev/null 2>&1; then
        # Local environment with sudo
        if sudo dpkg -i ../netsnmp-enterprise_2.0.0_all.deb; then
            echo "✅ Installation test successful"
            sudo dpkg -r netsnmp-enterprise
        else
            echo "❌ Installation test failed"
            exit 1
        fi
    else
        # CI environment - validate package structure instead
        echo "⚠️  sudo not available, validating package structure..."
        if dpkg-deb -I ../netsnmp-enterprise_2.0.0_all.deb >/dev/null && \
           dpkg-deb -c ../netsnmp-enterprise_2.0.0_all.deb | grep -q "usr/bin/netsnmp"; then
            echo "✅ Package validation successful"
        else
            echo "❌ Package validation failed"
            exit 1
        fi
    fi
else
    echo "❌ Package build failed"
    exit 1
fi