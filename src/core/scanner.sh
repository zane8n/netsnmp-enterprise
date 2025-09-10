#!/bin/bash
# Scanning functions for NetSnmp Enterprise

# Resolve SNMP hostname
resolve_snmp() {
    local ip="$1"
    local community
    
    IFS=' ' read -ra COMMUNITIES <<< "${CONFIG[communities]}"
    
    for community in "${COMMUNITIES[@]}"; do
        log_debug "Trying SNMP community on $ip"
        
        result=$(timeout "${CONFIG[snmp_timeout]}" \
            snmpget -v2c -c "$community" -Oqv "$ip" sysName.0 2>/dev/null)
        
        local exit_code=$?
        
        if [[ $exit_code -eq 0 ]] && [[ -n "$result" ]] && 
           [[ ! "$result" =~ "No Such Object" ]] && 
           [[ ! "$result" =~ "Timeout" ]]; then
            log_debug "SNMP response: $result"
            echo "$result" | tr -d '\r\n'
            return 0
        fi
    done
    
    log_debug "No valid SNMP response from $ip"
    return 1
}

# Scan single host
scan_single_host() {
    local ip="$1"
    
    log_debug "Scanning single host: $ip"
    
    # Check if host is alive
    if is_command_available "fping"; then
        fping -c1 -t"${CONFIG[ping_timeout]}00" "$ip" &>/dev/null
    else
        ping -c1 -W"${CONFIG[ping_timeout]}" "$ip" &>/dev/null
    fi
    
    if [[ $? -eq 0 ]]; then
        local hostname=$(resolve_snmp "$ip")
        if [[ -n "$hostname" ]]; then
            echo "Host: $ip"
            echo "Name: $hostname"
            return 0
        else
            echo "Host $ip is alive but no SNMP response"
        fi
    else
        echo "Host $ip is not responding"
    fi
    
    return 1
}

# Scan host (used by parallel scanning)
scan_host() {
    local ip="$1"
    
    log_debug "Pinging $ip..."
    
    if is_command_available "fping"; then
        fping -c1 -t"${CONFIG[ping_timeout]}00" "$ip" &>/dev/null
    else
        ping -c1 -W"${CONFIG[ping_timeout]}" "$ip" &>/dev/null
    fi
    
    local ping_result=$?
    log_debug "Ping result for $ip: $ping_result"
    
    if [[ $ping_result -eq 0 ]]; then
        log_debug "Host alive: $ip, querying SNMP..."
        local hostname=$(resolve_snmp "$ip")
        
        if [[ -n "$hostname" ]]; then
            log_debug "SNMP success: $ip -> $hostname"
            echo "$ip $hostname"
            return 0
        else
            log_debug "Host alive but no SNMP response: $ip"
        fi
    else
        log_debug "Host not responding: $ip"
    fi
    
    return 1
}

# Scan network using parallel processing
scan_network() {
    local network="$1"
    local ip_list=$(generate_ip_list "$network")
    
    if [[ $? -ne 0 ]] || [[ -z "$ip_list" ]]; then
        log_error "Failed to generate IP list for network: $network"
        return 1
    fi
    
    local ip_count=$(echo "$ip_list" | wc -l)
    log_debug "Scanning $ip_count IPs in network: $network"
    
    # Use parallel if available, otherwise use background jobs
    if command -v parallel >/dev/null 2>&1; then
        echo "$ip_list" | parallel -j "${CONFIG[scan_workers]}" '
            if result=$(scan_host "$1" 2>/dev/null); then
                echo "$result"
            fi
        '
    else
        local counter=0
        local temp_result_file=$(mktemp)
        
        while read -r ip; do
            (
                if result=$(scan_host "$ip" 2>/dev/null); then
                    echo "$result" >> "$temp_result_file"
                fi
            ) &
            
            ((counter++))
            
            if [[ $((counter % ${CONFIG[scan_workers]})) -eq 0 ]]; then
                wait
            fi
            
        done <<< "$ip_list"
        
        wait
        cat "$temp_result_file" 2>/dev/null
        rm -f "$temp_result_file"
    fi
}

# Test SNMP connectivity
test_snmp_connectivity() {
    local ip="$1"
    
    if [[ -z "$ip" ]]; then
        echo "Usage: netsnmp --test-snmp <IP>"
        echo "Example: netsnmp --test-snmp 10.134.7.1"
        return 1
    fi
    
    load_config
    
    echo "Testing SNMP on: $ip"
    echo "Communities: ${CONFIG[communities]}"
    echo ""
    
    IFS=' ' read -ra COMMUNITIES <<< "${CONFIG[communities]}"
    
    for community in "${COMMUNITIES[@]}"; do
        echo "Trying community: $community"
        result=$(timeout 2 snmpget -v2c -c "$community" -Oqv "$ip" sysName.0 2>&1)
        exit_code=$?
        
        echo "Exit code: $exit_code"
        echo "Response: $result"
        echo "---"
        
        if [[ $exit_code -eq 0 ]] && [[ -n "$result" ]] && 
           [[ ! "$result" =~ "No Such Object" ]] && 
           [[ ! "$result" =~ "Timeout" ]]; then
            echo "✅ SUCCESS: $result"
            return 0
        fi
    done
    
    echo "❌ All SNMP attempts failed"
    return 1
}

# Run test scan
run_test_scan() {
    echo "Testing scan functionality..."
    echo ""
    
    load_config
    
    echo "1. Testing network connectivity..."
    if ping -c 1 -W 1 8.8.8.8 &>/dev/null; then
        echo "   ✅ Network connectivity: OK"
    else
        echo "   ❌ Network connectivity: FAILED"
    fi
    
    echo "2. Testing SNMP utilities..."
    if command -v snmpget &>/dev/null; then
        echo "   ✅ snmpget command: FOUND"
    else
        echo "   ❌ snmpget command: MISSING"
    fi
    
    echo "3. Testing configuration..."
    if [[ -n "${CONFIG[subnets]}" ]]; then
        echo "   ✅ Networks configured: ${CONFIG[subnets]}"
    else
        echo "   ❌ No networks configured"
    fi
    
    if [[ -n "${CONFIG[communities]}" ]]; then
        echo "   ✅ SNMP communities: ${CONFIG[communities]}"
    else
        echo "   ❌ No SNMP communities configured"
    fi
    
    echo "4. Testing single host scan..."
    if scan_single_host "127.0.0.1" &>/dev/null; then
        echo "   ✅ Single host scan: OK"
    else
        echo "   ⚠️  Single host scan: No response (expected for localhost)"
    fi
    
    echo ""
    echo "Test scan completed."
}