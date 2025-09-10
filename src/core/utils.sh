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
    
    # Handle CIDR notation (e.g., 10.134.7.0/24)
    if [[ "$network" == *"/"* ]]; then
        # Use prips if available (most efficient)
        if command -v prips >/dev/null 2>&1; then
            prips "$network" 2>/dev/null
            local exit_code=$?
            if [[ $exit_code -eq 0 ]]; then
                local count=$(prips "$network" 2>/dev/null | wc -l)
                log_debug "Generated $count IPs for CIDR: $network (using prips)"
                return 0
            fi
        fi
        
        # Use ipcalc if available
        if command -v ipcalc >/dev/null 2>&1; then
            local network_info=$(ipcalc -n -b "$network" 2>/dev/null)
            if [[ $? -eq 0 ]]; then
                local network_address=$(echo "$network_info" | awk '/^Network:/ {print $2}')
                local broadcast=$(echo "$network_info" | awk '/^Broadcast:/ {print $2}')
                
                if [[ -n "$network_address" && -n "$broadcast" ]]; then
                    # Use prips with network range if available
                    if command -v prips >/dev/null 2>&1; then
                        prips "$network_address" "$broadcast" | head -n -1 | tail -n +2
                    else
                        # Fallback: generate IPs manually for common subnet sizes
                        local base="${network_address%.*}"
                        local prefix="${network#*/}"
                        
                        case "$prefix" in
                            24)
                                for i in {1..254}; do
                                    echo "${base}.${i}"
                                done
                                ;;
                            25)
                                for i in {1..126}; do
                                    echo "${base}.${i}"
                                done
                                ;;
                            26)
                                for i in {1..62}; do
                                    echo "${base}.${i}"
                                done
                                ;;
                            27)
                                for i in {1..30}; do
                                    echo "${base}.${i}"
                                done
                                ;;
                            28)
                                for i in {1..14}; do
                                    echo "${base}.${i}"
                                done
                                ;;
                            29)
                                for i in {1..6}; do
                                    echo "${base}.${i}"
                                done
                                ;;
                            30)
                                for i in {1..2}; do
                                    echo "${base}.${i}"
                                done
                                ;;
                            *)
                                log_error "Complex subnet mask not yet supported: /$prefix"
                                return 1
                                ;;
                        esac
                    fi
                    
                    local count=$(generate_ip_list "$network" | wc -l)
                    log_debug "Generated $count IPs for CIDR: $network (using ipcalc)"
                    return 0
                fi
            fi
        fi
        
        # Fallback: manual CIDR handling for common cases
        local subnet="${network%/*}"
        local prefix="${network#*/}"
        
        if ! [[ "$prefix" =~ ^[0-9]+$ ]]; then
            log_error "Invalid CIDR prefix: $prefix"
            return 1
        fi
        
        # Only support common subnet sizes that we can handle manually
        case "$prefix" in
            24)
                local base="${subnet%.*}"
                for i in {1..254}; do
                    echo "${base}.${i}"
                done
                log_debug "Generated 254 IPs for CIDR: $network"
                ;;
            25|26|27|28|29|30)
                log_error "Complex subnet mask /$prefix requires prips or ipcalc"
                log_error "Please install prips or ipcalc package"
                return 1
                ;;
            *)
                log_error "Complex subnet masks not yet supported: /$prefix"
                return 1
                ;;
        esac
    
    # Handle IP ranges (e.g., 10.134.7.1-100)
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
    
    # Handle single IP (e.g., 10.134.7.1)
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