#!/bin/bash
# Post-installation setup for NetSnmp Enterprise

# Run post-installation tasks
run_postinstall() {
    print_status "Running post-installation setup..."
    
    # Create necessary directories
    create_directories
    
    # Set proper permissions
    set_permissions
    
    # Initialize configuration if needed
    initialize_config
    
    # Create systemd service if requested
    create_systemd_service
    
    # Test installation
    test_installation
    
    print_success "Post-installation setup completed"
}

# Create necessary directories
create_directories() {
    local dirs=(
        "$CACHE_DIR"
        "$(dirname "$LOG_DIR/netsnmp.log")"
        "/var/lib/netsnmp"
    )
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            print_status "Created directory: $dir"
        fi
    done
}

# Set proper permissions
set_permissions() {
    print_status "Setting permissions..."
    
    # Set cache directory permissions
    chmod 755 "$CACHE_DIR"
    chmod 755 "/var/lib/netsnmp"
    
    # Ensure log file is writable
    touch "$LOG_DIR/netsnmp.log"
    chmod 644 "$LOG_DIR/netsnmp.log"
    
    # Set config file permissions
    if [[ -f "$CONFIG_DIR/netsnmp.conf" ]]; then
        chmod 644 "$CONFIG_DIR/netsnmp.conf"
    fi
    
    print_success "Permissions set successfully"
}

# Initialize configuration
initialize_config() {
    print_status "Initializing configuration..."
    
    if [[ ! -f "$CONFIG_DIR/netsnmp.conf" ]] || [[ ! -s "$CONFIG_DIR/netsnmp.conf" ]]; then
        print_status "Creating default configuration..."
        cat > "$CONFIG_DIR/netsnmp.conf" << 'EOF'
# NetSnmp Enterprise Configuration
# Generated on $(date)

# Networks to scan (space separated)
# Examples: 192.168.1.0/24, 10.0.0.1-100, 172.16.1.50
subnets="192.168.1.0/24 10.0.0.0/24"

# SNMP communities to try (space separated)
communities="public private"

# Ping timeout in seconds
ping_timeout="1"

# SNMP timeout in seconds
snmp_timeout="2"

# Number of parallel workers for scanning
scan_workers="10"

# Cache TTL in seconds (3600 = 1 hour)
cache_ttl="3600"

# Enable logging (true/false)
enable_logging="true"

# Automatic scan interval (0 = disabled)
scan_interval="0"

# Email notifications (requires mail setup)
email_notifications="false"
email_recipient=""
EOF
        
        print_success "Default configuration created: $CONFIG_DIR/netsnmp.conf"
    else
        print_status "Configuration already exists: $CONFIG_DIR/netsnmp.conf"
    fi
}

# Create systemd service for automated scanning
create_systemd_service() {
    if [[ ! -d "/etc/systemd/system" ]]; then
        print_warning "Systemd not found, skipping service creation"
        return 0
    fi
    
    read -p "Create systemd service for automated scanning? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Creating systemd service..."
        
        cat > "/etc/systemd/system/netsnmp.service" << 'EOF'
[Unit]
Description=NetSnmp Enterprise Network Scanner
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/netsnmp --update
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF
        
        cat > "/etc/systemd/system/netsnmp.timer" << 'EOF'
[Unit]
Description=Run NetSnmp scan daily
Requires=netsnmp.service

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF
        
        # Enable and start the timer
        systemctl daemon-reload
        systemctl enable netsnmp.timer
        systemctl start netsnmp.timer
        
        print_success "Systemd service created and enabled"
        print_status "Daily scans will run automatically"
    else
        print_status "Skipping systemd service creation"
    fi
}

# Test the installation
test_installation() {
    print_status "Testing installation..."
    
    # Test if binary is executable
    if [[ ! -x "$INSTALL_DIR/netsnmp" ]]; then
        print_error "Binary is not executable: $INSTALL_DIR/netsnmp"
        return 1
    fi
    
    # Test if binary works
    if "$INSTALL_DIR/netsnmp" --version >/dev/null 2>&1; then
        print_success "Binary test passed"
    else
        print_error "Binary test failed"
        return 1
    fi
    
    # Test configuration
    if [[ -f "$CONFIG_DIR/netsnmp.conf" ]]; then
        print_success "Configuration file exists"
    else
        print_error "Configuration file missing"
        return 1
    fi
    
    # Test dependencies
    if check_dependencies; then
        print_success "Dependency check passed"
    else
        print_warning "Some dependencies may be missing"
    fi
    
    print_success "Installation test completed successfully"
}

# Create uninstall script
create_uninstall_script() {
    local uninstall_script="/tmp/netsnmp-uninstall.sh"
    
    cat > "$uninstall_script" << 'EOF'
#!/bin/bash
# NetSnmp Enterprise Uninstall Script

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check root
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root"
    exit 1
fi

print_status "Starting NetSnmp Enterprise uninstallation..."

# Remove binary
if [[ -f "/usr/local/bin/netsnmp" ]]; then
    rm -f "/usr/local/bin/netsnmp"
    print_status "Removed binary: /usr/local/bin/netsnmp"
fi

# Remove man page
if [[ -f "/usr/local/share/man/man1/netsnmp.1.gz" ]]; then
    rm -f "/usr/local/share/man/man1/netsnmp.1.gz"
    print_status "Removed man page"
fi

# Remove configuration (ask first)
read -p "Remove configuration files? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "/etc/netsnmp"
    print_status "Removed configuration files"
else
    print_status "Keeping configuration files"
fi

# Remove cache (ask first)
read -p "Remove cache files? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "/var/cache/netsnmp"
    print_status "Removed cache files"
else
    print_status "Keeping cache files"
fi

# Remove systemd service if exists
if [[ -f "/etc/systemd/system/netsnmp.service" ]]; then
    systemctl stop netsnmp.timer 2>/dev/null || true
    systemctl disable netsnmp.timer 2>/dev/null || true
    rm -f "/etc/systemd/system/netsnmp.service"
    rm -f "/etc/systemd/system/netsnmp.timer"
    systemctl daemon-reload
    print_status "Removed systemd service"
fi

# Remove log file (ask first)
read -p "Remove log file? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -f "/var/log/netsnmp.log"
    print_status "Removed log file"
else
    print_status "Keeping log file"
fi

print_status "Uninstallation completed successfully!"
EOF
    
    chmod +x "$uninstall_script"
    mv "$uninstall_script" "/usr/local/bin/netsnmp-uninstall.sh"
    
    print_status "Uninstall script created: /usr/local/bin/netsnmp-uninstall.sh"
    print_status "Run: sudo /usr/local/bin/netsnmp-uninstall.sh"
}

# Generate uninstall script for --uninstall-script option
generate_uninstall_script() {
    cat << 'EOF'
#!/bin/bash
# NetSnmp Enterprise Uninstall Script

echo "Uninstalling NetSnmp Enterprise..."

# Remove binary
rm -f /usr/local/bin/netsnmp

# Remove man page
rm -f /usr/local/share/man/man1/netsnmp.1.gz

# Remove configuration
read -p "Remove configuration files? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf /etc/netsnmp
    echo "Configuration files removed"
fi

# Remove cache
read -p "Remove cache files? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf /var/cache/netsnmp
    echo "Cache files removed"
fi

# Remove systemd service
if [[ -f "/etc/systemd/system/netsnmp.service" ]]; then
    systemctl stop netsnmp.timer 2>/dev/null || true
    systemctl disable netsnmp.timer 2>/dev/null || true
    rm -f /etc/systemd/system/netsnmp.service
    rm -f /etc/systemd/system/netsnmp.timer
    systemctl daemon-reload
    echo "Systemd service removed"
fi

# Remove log file
read -p "Remove log file? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -f /var/log/netsnmp.log
    echo "Log file removed"
fi

echo "Uninstallation complete!"
EOF
}