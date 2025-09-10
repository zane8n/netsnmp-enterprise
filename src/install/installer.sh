#!/bin/bash
# NetSnmp Enterprise Installer
# Version: 2.0.0

set -e

VERSION="2.0.0"
INSTALL_DIR="/usr/bin"
CONFIG_DIR="/etc/netsnmp"
MAN_DIR="/usr/share/man/man1"
CACHE_DIR="/var/cache/netsnmp"
LOG_DIR="/var/log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Source dependencies
source "$(dirname "${BASH_SOURCE[0]}")/dependencies.sh"

# Print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root for system-wide installation"
        print_status "Use: sudo $0"
        print_status "For user installation: $0 --user"
        exit 1
    fi
}

# Check if running as user
check_user() {
    if [[ $EUID -eq 0 ]]; then
        print_warning "Running as root for user installation is not recommended"
        print_status "Continuing with user installation..."
    fi
}

# Detect Linux distribution
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$ID"
    elif [[ -f /etc/redhat-release ]]; then
        echo "rhel"
    elif [[ -f /etc/arch-release ]]; then
        echo "arch"
    else
        echo "unknown"
    fi
}

# System-wide installation
install_system_wide() {
    print_status "Starting system-wide installation of NetSnmp Enterprise v${VERSION}"
    
    local distro=$(detect_distro)
    print_status "Detected distribution: $distro"
    
    # Install dependencies
    install_dependencies "$distro"
    
    # Create directories
    print_status "Creating directories..."
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$CACHE_DIR"
    mkdir -p "$MAN_DIR"
    mkdir -p "$LOG_DIR"
    
    # Install main binary
    print_status "Installing main binary..."
    cp -f ../core/main.sh "$INSTALL_DIR/netsnmp"
    chmod 755 "$INSTALL_DIR/netsnmp"
    
    # Install man page
    print_status "Installing man page..."
    cp -f ../../man/netsnmp.1 "$MAN_DIR/"
    gzip -f "$MAN_DIR/netsnmp.1"
    
    # Install default config if it doesn't exist
    if [[ ! -f "$CONFIG_DIR/netsnmp.conf" ]]; then
        print_status "Installing default configuration..."
        cp -f ../../config/netsnmp.conf "$CONFIG_DIR/"
        chmod 644 "$CONFIG_DIR/netsnmp.conf"
    fi
    
    # Set permissions
    chmod 755 "$INSTALL_DIR/netsnmp"
    chmod 644 "$MAN_DIR/netsnmp.1.gz"
    chmod 755 "$CACHE_DIR"
    
    # Create log file
    touch "$LOG_DIR/netsnmp.log"
    chmod 644 "$LOG_DIR/netsnmp.log"
    
    # Run post-install setup
    run_postinstall
    
    print_success "Installation completed successfully!"
    print_status "Binary installed to: $INSTALL_DIR/netsnmp"
    print_status "Configuration: $CONFIG_DIR/netsnmp.conf"
    print_status "Cache directory: $CACHE_DIR"
    print_status "Log file: $LOG_DIR/netsnmp.log"
    
    show_next_steps
}

# User-specific installation
install_user() {
    print_status "Starting user-specific installation of NetSnmp Enterprise v${VERSION}"
    
    check_user
    
    local user_bin="$HOME/.local/bin"
    local user_config="$HOME/.config/netsnmp"
    local user_cache="$HOME/.cache/netsnmp"
    local user_man="$HOME/.local/share/man/man1"
    
    # Create user directories
    print_status "Creating user directories..."
    mkdir -p "$user_bin"
    mkdir -p "$user_config"
    mkdir -p "$user_cache"
    mkdir -p "$user_man"
    
    # Install main binary
    print_status "Installing main binary..."
    cp -f ../core/main.sh "$user_bin/netsnmp"
    chmod 755 "$user_bin/netsnmp"
    
    # Install man page
    print_status "Installing man page..."
    cp -f ../../man/netsnmp.1 "$user_man/"
    gzip -f "$user_man/netsnmp.1"
    
    # Install default config
    print_status "Installing default configuration..."
    cp -f ../../config/netsnmp.conf "$user_config/"
    chmod 644 "$user_config/netsnmp.conf"
    
    # Add to PATH if not already
    if [[ ":$PATH:" != *":$user_bin:"* ]]; then
        print_status "Adding ~/.local/bin to PATH..."
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
        print_status "Run: source ~/.bashrc or restart your terminal"
    fi
    
    print_success "User installation completed successfully!"
    print_status "Binary installed to: $user_bin/netsnmp"
    print_status "Configuration: $user_config/netsnmp.conf"
    print_status "Cache directory: $user_cache"
    
    show_next_steps_user
}

# Show next steps after installation
show_next_steps() {
    echo ""
    print_status "Next steps:"
    echo "  1. Configure the tool:"
    echo "     sudo netsnmp --wizard"
    echo "  2. Scan your network:"
    echo "     sudo netsnmp --update"
    echo "  3. Search for devices:"
    echo "     netsnmp switch"
    echo "     netsnmp router"
    echo "  4. View help:"
    echo "     netsnmp --help"
    echo ""
    print_status "Uninstall with:"
    echo "  sudo netsnmp --uninstall-script | bash"
}

show_next_steps_user() {
    echo ""
    print_status "Next steps:"
    echo "  1. Configure the tool:"
    echo "     netsnmp --wizard"
    echo "  2. Scan your network:"
    echo "     netsnmp --update"
    echo "  3. Search for devices:"
    echo "     netsnmp switch"
    echo "  4. View help:"
    echo "     netsnmp --help"
    echo ""
    print_status "Note: Some features may require root privileges for full functionality"
}

# Show usage
show_usage() {
    echo "NetSnmp Enterprise Installer v${VERSION}"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  --system    Install system-wide (requires sudo)"
    echo "  --user      Install for current user only"
    echo "  --help      Show this help message"
    echo ""
    echo "Default: system-wide installation"
}

# Main installer function
main() {
    local install_type="system"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --system)
                install_type="system"
                shift
                ;;
            --user)
                install_type="user"
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    case "$install_type" in
        system)
            check_root
            install_system_wide
            ;;
        user)
            install_user
            ;;
        *)
            print_error "Invalid installation type"
            exit 1
            ;;
    esac
}

# Only run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi