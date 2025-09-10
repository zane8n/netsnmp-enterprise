#!/bin/bash
# PPA setup and deployment script

set -e

PPA_NAME="netsnmp-enterprise"
PPA_URL="https://ppa.launchpadcontent.net/ky6/$PPA_NAME/ubuntu"
DISTRIBUTIONS="focal jammy noble"

setup_ppa() {
    echo "Setting up NetSnmp Enterprise PPA..."
    
    # Install required tools
    sudo apt-get update
    sudo apt-get install -y devscripts debmake dh-make build-essential
    
    # Create package source
    cd packaging/deb
    
    # Build source package
    debuild -S -sa -k$GPG_KEY_ID
    
    # Upload to PPA
    for distro in $DISTRIBUTIONS; do
        echo "Uploading to $distro..."
        dput ppa:ky6/$PPA_NAME ../netsnmp-enterprise_2.0.0-1_source.changes
    done
    
    echo "✅ PPA setup completed!"
    echo "Packages available at: $PPA_URL"
}

add_ppa_to_readme() {
    cat >> ../../README.md << EOF

## Ubuntu/Debian Installation (PPA)

\`\`\`bash
# Add PPA
sudo add-apt-repository ppa:ky6/netsnmp-enterprise
sudo apt-get update

# Install NetSnmp Enterprise
sudo apt-get install netsnmp-enterprise
\`\`\`
EOF
}

main() {
    if [[ -z "$GPG_KEY_ID" ]]; then
        echo "Error: GPG_KEY_ID environment variable not set"
        echo "Run: export GPG_KEY_ID=your-key-id"
        exit 1
    fi
    
    setup_ppa
    add_ppa_to_readme
}

main "$@"