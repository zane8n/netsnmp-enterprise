#!/bin/bash
# RPM package build script

set -e

cd "$(dirname "$0")"
ROOT_DIR="../../.."

echo "Building RPM package for NetSnmp Enterprise..."

# Check if required tools are installed
if ! command -v rpmbuild >/dev/null 2>&1; then
    echo "Error: rpmbuild not found. Install rpm-build package."
    exit 1
fi

# Clean previous builds
rm -rf ~/rpmbuild/BUILD/*
rm -rf ~/rpmbuild/BUILDROOT/*
rm -rf ~/rpmbuild/RPMS/*
rm -rf ~/rpmbuild/SOURCES/*
rm -rf ~/rpmbuild/SPECS/*

# Create source tarball
cd "$ROOT_DIR"
make clean
make
tar czf ../../packaging/rpm/netsnmp-enterprise-2.0.0.tar.gz --exclude=.git --exclude=packaging .

# Set up RPM build environment
mkdir -p ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
cp packaging/rpm/netsnmp-enterprise-2.0.0.tar.gz ~/rpmbuild/SOURCES/
cp packaging/rpm/netsnmp.spec ~/rpmbuild/SPECS/

# Build the RPM package
cd ~/rpmbuild/SPECS
rpmbuild -ba netsnmp.spec

# Check if package was built successfully
if [[ -f ~/rpmbuild/RPMS/noarch/netsnmp-enterprise-2.0.0-1.*.noarch.rpm ]]; then
    echo ""
    echo "✅ RPM package built successfully:"
    
    # Copy package to packaging directory
    cp ~/rpmbuild/RPMS/noarch/netsnmp-enterprise-2.0.0-1.*.noarch.rpm ../../packaging/rpm/
    cp ~/rpmbuild/SRPMS/netsnmp-enterprise-2.0.0-1.*.src.rpm ../../packaging/rpm/
    
    # Show package info
    echo "Package information:"
    rpm -qip ~/rpmbuild/RPMS/noarch/netsnmp-enterprise-2.0.0-1.*.noarch.rpm
    
    # Test installation
    echo ""
    echo "Testing installation..."
    if sudo rpm -ivh ~/rpmbuild/RPMS/noarch/netsnmp-enterprise-2.0.0-1.*.noarch.rpm; then
        echo "✅ Installation test successful"
        sudo rpm -e netsnmp-enterprise
    else
        echo "❌ Installation test failed"
        exit 1
    fi
else
    echo "❌ RPM package build failed"
    exit 1
fi