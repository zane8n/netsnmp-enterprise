#!/bin/bash
# Utility functions for NetSnmp Enterprise

# Check if a command is available
is_command_available() {
    command -v "$1" &> /dev/null
}

# Detect package manager
detect_package_manager() {
    if is_command_available "apt"; then
        echo "deb"
    elif is_command_available "yum"; then
        echo "rpm"
    elif is_command_available "dnf"; then
        echo "rpm"
    elif is_command_available "pacman"; then
        echo "arch"
    elif is_command_available "zypper"; then
        echo "suse"
    else
        echo "unknown"
    fi
}

# Generate IP list from network specification
generate_ip_list() {
    local network="$1"
    
    log_debug "Generating IP list for: $network"
    
    # Handle CIDR notation
    if [[ "$network" == *"/"* ]]; then
        local subnet="${network%/*}"
        local prefix="${network#*/}"
        
        if [[ "$prefix" == "24" ]]; then
            local base="${subnet%.*}"
            for i in {1..254}; do
                echo "${base}.${i}"
            done
            log_debug "Generated 254 IPs for CIDR: $network"
        else
            log_error "Complex subnet masks not yet supported: $network"
            return 1
        fi
    
    # Handle IP ranges
    elif [[ "$network" == *"-"* ]]; then
        local base_ip="${network%-*}"
        local end_range="${network#*-}"
        local last_octet="${base_ip##*.}"
        local base_network="${base_ip%.*}"
        
        if ! [[ "$last_octet" =~ ^[0-9]+$ ]] || ! [[ "$end_range" =~ ^[0-9]+$ ]]; then
            log_error "Invalid IP range format: $network"
            return 1
        fi
        
        if [[ "$last_octet" -gt "$end_range" ]]; then
            log_error "Invalid range: start ($last_octet) > end ($end_range)"
            return 1
        fi
        
        for i in $(seq "$last_octet" "$end_range"); do
            echo "${base_network}.${i}"
        done
        
        local count=$((end_range - last_octet + 1))
        log_debug "Generated $count IPs for range: $network"
    
    # Handle single IP
    else
        if [[ "$network" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "$network"
            log_debug "Single IP: $network"
        else
            log_error "Invalid IP address format: $network"
            return 1
        fi
    fi
}

# Test IP generation
test_ip_generation() {
    local network="$1"
    
    if [[ -z "$network" ]]; then
        echo "Usage: netsnmp --test-ips <network>"
        echo "Example: netsnmp --test-ips 10.134.7.1-10"
        return 1
    fi
    
    echo "Testing IP generation for: $network"
    echo "Generated IPs:"
    
    local ip_list=$(generate_ip_list "$network")
    if [[ $? -eq 0 ]]; then
        echo "$ip_list"
        echo ""
        echo "Total: $(echo "$ip_list" | wc -l) IP addresses"
    else
        echo "Failed to generate IPs"
    fi
}

# Validate IP address
validate_ip() {
    local ip="$1"
    if [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}

# Get timestamp
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}