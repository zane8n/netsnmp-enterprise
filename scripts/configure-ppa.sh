#!/bin/bash
# PPA configuration script

set -e

echo "Configuring PPA for NetSnmp Enterprise..."

# Check if we're in the right directory
if [ ! -f "debian/changelog" ]; then
    echo "This script must be run from packaging/deb directory"
    exit 1
fi

# Update changelog for PPA
if [ -n "$1" ]; then
    VERSION="$1"
    dch -v "${VERSION}-1" "New upstream release"
    dch -r --distribution stable ""
    echo "Updated changelog to version: ${VERSION}-1"
fi

# Ensure proper build dependencies
echo "Checking build dependencies..."
if ! command -v debuild >/dev/null 2>&1; then
    echo "Installing devscripts..."
    sudo apt-get install -y devscripts debhelper
fi

echo "PPA configuration complete! ✅"