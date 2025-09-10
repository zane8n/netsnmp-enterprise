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
        local subnet="${network%/*}"
        local prefix="${network#*/}"
        
        if ! [[ "$prefix" =~ ^[0-9]+$ ]]; then
            log_error "Invalid CIDR prefix: $prefix"
            return 1
        fi
        
        # Try prips first (most efficient)
        if command -v prips >/dev/null 2>&1; then
            prips "$network" 2>/dev/null
            if [[ $? -eq 0 ]]; then
                local count=$(prips "$network" 2>/dev/null | wc -l)
                log_debug "Generated $count IPs for CIDR: $network (using prips)"
                return 0
            fi
        fi
        
        # Try ipcalc next
        if command -v ipcalc >/dev/null 2>&1; then
            local network_info=$(ipcalc -n -b "$network" 2>/dev/null)
            if [[ $? -eq 0 ]]; then
                local network_address=$(echo "$network_info" | awk '/^Network:/ {print $2}')
                local broadcast=$(echo "$network_info" | awk '/^Broadcast:/ {print $2}')
                
                if [[ -n "$network_address" && -n "$broadcast" ]]; then
                    # Generate IP range manually
                    IFS='.' read -r i1 i2 i3 i4 <<< "$network_address"
                    IFS='.' read -r b1 b2 b3 b4 <<< "$broadcast"
                    
                    # Only generate usable hosts (exclude network and broadcast)
                    for ((i=$i4+1; i<$b4; i++)); do
                        echo "$i1.$i2.$i3.$i"
                    done
                    
                    local count=$((b4 - i4 - 1))
                    log_debug "Generated $count IPs for CIDR: $network (using ipcalc)"
                    return 0
                fi
            fi
        fi
        
        # Manual fallback for common subnet sizes
        local base="${subnet%.*}"
        
        case "$prefix" in
            24)
                for i in {1..254}; do
                    echo "${base}.${i}"
                done
                log_debug "Generated 254 IPs for CIDR: $network (manual /24)"
                ;;
            30)
                for i in {1..2}; do
                    echo "${base}.${i}"
                done
                log_debug "Generated 2 IPs for CIDR: $network (manual /30)"
                ;;
            25)
                for i in {1..126}; do
                    echo "${base}.${i}"
                done
                log_debug "Generated 126 IPs for CIDR: $network (manual /25)"
                ;;
            26)
                for i in {1..62}; do
                    echo "${base}.${i}"
                done
                log_debug "Generated 62 IPs for CIDR: $network (manual /26)"
                ;;
            27)
                for i in {1..30}; do
                    echo "${base}.${i}"
                done
                log_debug "Generated 30 IPs for CIDR: $network (manual /27)"
                ;;
            28)
                for i in {1..14}; do
                    echo "${base}.${i}"
                done
                log_debug "Generated 14 IPs for CIDR: $network (manual /28)"
                ;;
            29)
                for i in {1..6}; do
                    echo "${base}.${i}"
                done
                log_debug "Generated 6 IPs for CIDR: $network (manual /29)"
                ;;
            *)
                log_error "Complex subnet masks not yet supported: /$prefix"
                log_error "Please install prips or ipcalc for full CIDR support"
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