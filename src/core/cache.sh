#!/bin/bash
# Cache management for NetSnmp Enterprise

# Check if cache is valid
is_cache_valid() {
    [[ -f "$CACHE_FILE" ]] && \
    [[ -s "$CACHE_FILE" ]] && \
    [[ $(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0))) -lt "${CONFIG[cache_ttl]}" ]]
}

# Show cache information
show_cache_info() {
    if [[ -f "$CACHE_FILE" ]]; then
        local total_hosts=$(wc -l < "$CACHE_FILE" 2>/dev/null || echo 0)
        local last_modified=$(stat -c %y "$CACHE_FILE" 2>/dev/null || echo "Unknown")
        local file_size=$(du -h "$CACHE_FILE" 2>/dev/null | cut -f1 || echo "Unknown")
        local age=$(( ($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)) / 60 ))
        
        echo "Cache File:    $CACHE_FILE"
        echo "Total Hosts:   $total_hosts"
        echo "Last Modified: $last_modified"
        echo "File Size:     $file_size"
        echo "Cache Age:     ${age} minutes"
        echo ""
        
        if [[ $total_hosts -gt 0 ]]; then
            echo "First 10 entries:"
            head -10 "$CACHE_FILE" 2>/dev/null | awk '{print "  → " $1 " (" $2 ")"}'
        else
            echo "Cache file is empty"
        fi
        
        if is_cache_valid; then
            echo ""
            log_success "Cache is valid and has data"
        else
            echo ""
            if [[ ! -f "$CACHE_FILE" ]]; then
                log_error "Cache file does not exist"
            elif [[ ! -s "$CACHE_FILE" ]]; then
                log_error "Cache file is empty"
            else
                log_error "Cache is stale (older than TTL)"
            fi
        fi
    else
        log_error "No cache file found at: $CACHE_FILE"
        return 1
    fi
}

# Clear cache
clear_cache() {
    if rm -f "$CACHE_FILE" 2>/dev/null; then
        log_success "Cache cleared"
    else
        log_error "Failed to clear cache. Check permissions."
    fi
}

# Search cache for pattern
search_cache() {
    local pattern="${1^^}"
    local found=0
    
    if [[ ! -f "$CACHE_FILE" ]] || [[ ! -s "$CACHE_FILE" ]]; then
        log_error "Cache is empty or missing. Run 'netsnmp --update' first."
        return 1
    fi
    
    while read -r ip hostname; do
        local hostname_upper="${hostname^^}"
        local ip_upper="${ip^^}"
        
        if [[ "$hostname_upper" == *"$pattern"* ]] || 
           [[ "$ip_upper" == *"$pattern"* ]]; then
            echo "→ $ip ($hostname)"
            found=$((found + 1))
        fi
    done < "$CACHE_FILE"
    
    if [[ $found -eq 0 ]]; then
        log_error "No devices found matching '$1'"
        return 1
    else
        log "Found $found matching device(s)"
    fi
}

# Update cache
update_cache() {
    local custom_networks="${1:-}"
    local custom_communities="${2:-}"
    
    if ! load_config; then
        log_error "Cannot load configuration. Run 'netsnmp --wizard' first."
        return 1
    fi
    
    local scan_networks="${custom_networks:-${CONFIG[subnets]}}"
    local scan_communities="${custom_communities:-${CONFIG[communities]}}"
    
    local display_communities=$(echo "$scan_communities" | awk '{print $1}')
    if [[ $(echo "$scan_communities" | wc -w) -gt 1 ]]; then
        display_communities="$display_communities,..."
    fi
    
    log "Starting network scan..."
    log "Networks: $scan_networks"
    log "SNMP Communities: $display_communities"
    
    if touch "$CACHE_FILE" 2>/dev/null; then
        > "$CACHE_FILE"
    else
        log_error "Cannot write to cache file: $CACHE_FILE"
        return 1
    fi
    
    local total_found=0
    local original_networks="${CONFIG[subnets]}"
    local original_communities="${CONFIG[communities]}"
    
    CONFIG[subnets]="$scan_networks"
    CONFIG[communities]="$scan_communities"
    
    for network in ${CONFIG[subnets]}; do
        log "Scanning network: $network"
        
        local temp_file=$(mktemp)
        scan_network "$network" >> "$temp_file" 2>/dev/null
        
        local found_count=$(wc -l < "$temp_file" 2>/dev/null || echo 0)
        cat "$temp_file" >> "$CACHE_FILE" 2>/dev/null
        rm -f "$temp_file"
        
        total_found=$((total_found + found_count))
        log "Network $network: Found $found_count devices"
    done
    
    CONFIG[subnets]="$original_networks"
    CONFIG[communities]="$original_communities"
    
    if [[ $total_found -gt 0 ]]; then
        log_success "Scan completed. Total devices found: $total_found"
        return 0
    else
        log_error "No devices found. Check network configuration."
        return 1
    fi
}