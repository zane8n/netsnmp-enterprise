#!/bin/bash
# Package testing script

set -e

echo "Testing NetSnmp Enterprise packages..."
echo "======================================"

# Test Debian package
test_deb() {
    echo "Testing Debian package..."
    if [[ -f deb/netsnmp-enterprise_2.0.0_all.deb ]]; then
        # Test installation
        if sudo dpkg -i deb/netsnmp-enterprise_2.0.0_all.deb; then
            echo "✅ Debian package installation successful"
            
            # Test binary execution
            if netsnmp --version >/dev/null 2>&1; then
                echo "✅ Binary execution successful"
            else
                echo "❌ Binary execution failed"
                return 1
            fi
            
            # Test uninstallation
            if sudo dpkg -r netsnmp-enterprise; then
                echo "✅ Debian package uninstallation successful"
            else
                echo "❌ Debian package uninstallation failed"
                return 1
            fi
        else
            echo "❌ Debian package installation failed"
            return 1
        fi
    else
        echo "❌ Debian package not found"
        return 1
    fi
}

# Test RPM package
test_rpm() {
    echo "Testing RPM package..."
    local rpm_file=$(ls rpm/*.rpm 2>/dev/null | head -1)
    
    if [[ -f "$rpm_file" ]]; then
        # Test installation
        if sudo rpm -ivh "$rpm_file"; then
            echo "✅ RPM package installation successful"
            
            # Test binary execution
            if netsnmp --version >/dev/null 2>&1; then
                echo "✅ Binary execution successful"
            else
                echo "❌ Binary execution failed"
                return 1
            fi
            
            # Test uninstallation
            if sudo rpm -e netsnmp-enterprise; then
                echo "✅ RPM package uninstallation successful"
            else
                echo "❌ RPM package uninstallation failed"
                return 1
            fi
        else
            echo "❌ RPM package installation failed"
            return 1
        fi
    else
        echo "❌ RPM package not found"
        return 1
    fi
}

# Run tests
cd packaging

echo "Testing all available packages..."
echo ""

if test_deb; then
    echo "✅ Debian package tests passed"
else
    echo "❌ Debian package tests failed"
fi

echo ""

if test_rpm; then
    echo "✅ RPM package tests passed"
else
    echo "❌ RPM package tests failed"
fi

echo ""
echo "Package testing completed!"