#!/bin/bash
# Dependency management for NetSnmp Enterprise

# Install dependencies based on distribution
install_dependencies() {
    local distro="$1"
    
    print_status "Installing dependencies for $distro..."
    
    case "$distro" in
        ubuntu|debian)
            install_debian_deps
            ;;
        centos|rhel|fedora|rocky|almalinux)
            install_rpm_deps
            ;;
        arch|manjaro)
            install_arch_deps
            ;;
        opensuse*|suse*)
            install_suse_deps
            ;;
        *)
            install_unknown_deps
            ;;
    esac
}

# Debian/Ubuntu dependencies
install_debian_deps() {
    if ! command -v apt-get >/dev/null 2>&1; then
        print_error "apt-get not found. Cannot install dependencies."
        return 1
    fi
    
    print_status "Updating package list..."
    apt-get update
    
    print_status "Installing required packages..."
    apt-get install -y \
        snmp \
        snmpd \
        snmp-mibs-downloader \
        iputils-ping \
        fping \
        parallel \
        curl \
        wget \
        prips
    
    print_success "Debian dependencies installed successfully"
}

# RPM-based distributions (CentOS, RHEL, Fedora, Rocky, AlmaLinux)
install_rpm_deps() {
    if command -v dnf >/dev/null 2>&1; then
        local pm="dnf"
    elif command -v yum >/dev/null 2>&1; then
        local pm="yum"
    else
        print_error "No package manager found (dnf/yum)"
        return 1
    fi
    
    print_status "Installing required packages using $pm..."
    
    if [[ "$pm" == "dnf" ]]; then
        dnf install -y \
            net-snmp \
            net-snmp-utils \
            iputils \
            fping \
            parallel \
            curl \
            wget \
            ipcalc
    else
        yum install -y \
            net-snmp \
            net-snmp-utils \
            iputils \
            fping \
            parallel \
            curl \
            wget \
            ipcalc
    fi
    
    print_success "RPM dependencies installed successfully"
}

# Arch Linux dependencies
install_arch_deps() {
    if ! command -v pacman >/dev/null 2>&1; then
        print_error "pacman not found. Cannot install dependencies."
        return 1
    fi
    
    print_status "Installing required packages..."
    pacman -Sy --noconfirm \
        net-snmp \
        iputils \
        fping \
        parallel \
        curl \
        wget \
        ipcalc
    
    print_success "Arch dependencies installed successfully"
}

# openSUSE/SUSE dependencies
install_suse_deps() {
    if ! command -v zypper >/dev/null 2>&1; then
        print_error "zypper not found. Cannot install dependencies."
        return 1
    fi
    
    print_status "Installing required packages..."
    zypper install -y \
        net-snmp \
        iputils \
        fping \
        parallel \
        curl \
        wget \
        ipcalc
    
    print_success "SUSE dependencies installed successfully"
}

# Unknown distribution - provide manual instructions
install_unknown_deps() {
    print_warning "Unknown distribution detected"
    print_status "Please manually install the following packages:"
    echo ""
    echo "Required:"
    echo "  - snmp (net-snmp tools)"
    echo "  - ping (iputils-ping or equivalent)"
    echo "  - fping (for parallel ping)"
    echo "  - parallel (GNU parallel for efficient scanning)"
    echo "  - curl or wget"
    echo ""
    echo "On Debian/Ubuntu:"
    echo "  sudo apt install snmp snmpd iputils-ping fping parallel curl"
    echo ""
    echo "On RHEL/CentOS/Fedora:"
    echo "  sudo dnf install net-snmp net-snmp-utils iputils fping parallel curl"
    echo ""
    echo "On Arch:"
    echo "  sudo pacman -S net-snmp iputils fping parallel curl"
    echo ""
    echo "On openSUSE:"
    echo "  sudo zypper install net-snmp iputils fping parallel curl"
    echo ""
    read -p "Press Enter to continue after installing dependencies..."
}

# Check if all required dependencies are installed
check_dependencies() {
    local missing_deps=()
    
    # Required commands
    local required_commands=("snmpget" "ping")
    local recommended_commands=("fping" "parallel")
    
    print_status "Checking required dependencies..."
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    for cmd in "${recommended_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            print_warning "Recommended tool not found: $cmd"
            print_status "Some features may be limited without $cmd"
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_error "Missing required dependencies:"
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep"
        done
        return 1
    else
        print_success "All required dependencies are installed"
        return 0
    fi
}

# Test dependency installation
test_dependencies() {
    print_status "Testing dependency installation..."
    
    local distro=$(detect_distro)
    print_status "Testing for distribution: $distro"
    
    # Test each package manager
    case "$distro" in
        ubuntu|debian)
            install_debian_deps
            ;;
        centos|rhel|fedora)
            install_rpm_deps
            ;;
        arch)
            install_arch_deps
            ;;
        *)
            install_unknown_deps
            ;;
    esac
    
    check_dependencies
}