#!/bin/bash
# NetSnmp Enterprise - Main Entry Point
# Version: 2.0.0

set -e

VERSION="2.0.0"
AUTHOR="NetSnmp Enterprise Team"
LICENSE="GPL-3.0"

# Configuration paths
if [[ $EUID -eq 0 ]]; then
    CONFIG_DIR="/etc/netsnmp"
    CACHE_DIR="/var/cache/netsnmp"
    LOG_FILE="/var/log/netsnmp.log"
else
    CONFIG_DIR="${HOME}/.config/netsnmp"
    CACHE_DIR="${HOME}/.cache/netsnmp"
    LOG_FILE="${HOME}/.cache/netsnmp.log"
fi

CACHE_FILE="${CACHE_DIR}/hosts.cache"
CONFIG_FILE="${CONFIG_DIR}/netsnmp.conf"

# Default configuration
declare -A CONFIG=(
    ["subnets"]=""
    ["communities"]=""
    ["ping_timeout"]="1"
    ["snmp_timeout"]="2"
    ["scan_workers"]="10"
    ["cache_ttl"]="3600"
    ["enable_logging"]="true"
)

# Source utility functions first
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/logging.sh"
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/cache.sh"
source "$(dirname "${BASH_SOURCE[0]}")/scanner.sh"

# Main function
main() {
    local ACTION="search"
    local PATTERN=""
    local SCAN_IP=""
    local CUSTOM_NETWORKS=""
    local CUSTOM_COMMUNITIES=""
    
    # Initialize logging
    init_logging
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                return 0
                ;;
            -u|--update)
                ACTION="update"
                ;;
            -i|--info)
                ACTION="info"
                ;;
            -c|--clear)
                ACTION="clear"
                ;;
            -q|--quiet)
                QUIET="true"
                ;;
            -v|--verbose)
                VERBOSE="true"
                ;;
            -vv|--debug)
                VERBOSE="true"
                DEBUG="true"
                set -x
                ;;
            -s|--scan)
                ACTION="scan-single"
                SCAN_IP="$2"
                shift
                ;;
            -S|--networks)
                CUSTOM_NETWORKS="$2"
                shift
                ;;
            -C|--communities)
                CUSTOM_COMMUNITIES="$2"
                shift
                ;;
            --config)
                ACTION="config"
                ;;
            --wizard)
                ACTION="wizard"
                ;;
            --version)
                echo "NetSnmp Enterprise v${VERSION}"
                echo "License: ${LICENSE}"
                return 0
                ;;
            --test-ips)
                ACTION="test-ips"
                TEST_NETWORK="$2"
                shift
                ;;
            --test-snmp)
                ACTION="test-snmp"
                TEST_IP="$2"
                shift
                ;;
            --test-scan)
                ACTION="test-scan"
                ;;
            --uninstall-script)
                generate_uninstall_script
                return 0
                ;;
            -*)
                log_error "Unknown option: $1"
                return 1
                ;;
            *)
                PATTERN="$1"
                ;;
        esac
        shift
    done
    
    # Initialize configuration
    if ! init_config; then
        log_error "Failed to initialize configuration"
        return 1
    fi
    
    # Execute the requested action
    case "$ACTION" in
        update)
            update_cache "$CUSTOM_NETWORKS" "$CUSTOM_COMMUNITIES"
            ;;
        info)
            show_cache_info
            ;;
        clear)
            clear_cache
            ;;
        config)
            show_config
            ;;
        wizard)
            run_config_wizard
            ;;
        scan-single)
            if [[ -z "$SCAN_IP" ]]; then
                log_error "No IP address specified for scan"
                return 1
            fi
            scan_single_host "$SCAN_IP"
            ;;
        search)
            handle_search "$PATTERN"
            ;;
        test-ips)
            test_ip_generation "$TEST_NETWORK"
            ;;
        test-snmp)
            test_snmp_connectivity "$TEST_IP"
            ;;
        test-scan)
            run_test_scan
            ;;
        *)
            log_error "Unknown action: $ACTION"
            return 1
            ;;
    esac
    
    return 0
}

# Handle search functionality
handle_search() {
    local pattern="$1"
    
    if ! is_cache_valid; then
        log "Cache missing, stale, or empty. Updating..."
        update_cache
    fi
    
    if [[ -z "$pattern" ]]; then
        [[ "$QUIET" != "true" ]] && log "All cached devices:"
        if [[ -f "$CACHE_FILE" ]] && [[ -s "$CACHE_FILE" ]]; then
            cat "$CACHE_FILE" | awk '{print "→ " $1 " (" $2 ")"}'
            [[ "$QUIET" != "true" ]] && log "$(wc -l < "$CACHE_FILE") total devices"
        else
            log_error "No devices in cache. Run 'netsnmp --update' first."
        fi
    else
        search_cache "$pattern"
    fi
}

# Show help
show_help() {
    cat << EOF
NetSnmp Enterprise - Network Device Discovery Tool v${VERSION}

Usage:
  netsnmp [OPTIONS] [PATTERN]

Options:
  -h, --help           Show this help message
  -u, --update         Scan network and update cache
  -i, --info           Show cache information
  -c, --clear          Clear the cache
  -q, --quiet          Quiet mode (minimal output)
  -v, --verbose        Verbose output
  -vv, --debug         Debug mode (very verbose with tracing)
  -s, --scan IP        Scan single IP address
  -S, --networks NETWORKS  Use custom networks for scan
  -C, --communities COMMS Use custom SNMP communities
  --config             Show configuration
  --wizard             Run configuration wizard
  --version            Show version
  --test-ips NETWORK   Test IP generation for a network
  --test-snmp IP       Test SNMP connectivity to an IP
  --test-scan          Test scan functionality

Examples:
  netsnmp --update
  netsnmp switch
  netsnmp --scan 192.168.1.1
  netsnmp --test-ips 10.0.0.1-5
EOF
}

generate_uninstall_script() {
    cat << 'EOF'
#!/bin/bash
# NetSnmp Enterprise Uninstall Script

echo "Uninstalling NetSnmp Enterprise..."

# Remove binary
rm -f /usr/local/bin/netsnmp

# Remove man page
rm -f /usr/local/share/man/man1/netsnmp.1.gz

# Remove configuration and cache
read -p "Remove configuration and cache files? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf /etc/netsnmp
    rm -rf /var/cache/netsnmp
    echo "Configuration and cache removed"
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

# Only run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi