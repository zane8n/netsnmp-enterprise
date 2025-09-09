#!/bin/bash
# GPG signing setup script

set -e

GPG_KEY_NAME="NetSnmp Enterprise Signing Key"
GPG_KEY_EMAIL="safarikikandi@gmail.com"
GPG_KEY_COMMENT="Package Signing Key"
GPG_EXPIRY="2y"  # 2 years expiration

setup_gpg() {
    echo "Setting up GPG signing for NetSnmp Enterprise..."
    
    # Check if GPG is installed
    if ! command -v gpg >/dev/null 2>&1; then
        echo "Error: GPG not installed. Please install gnupg package."
        exit 1
    fi
    
    # Check if key already exists
    if gpg --list-secret-keys --keyid-format LONG "$GPG_KEY_EMAIL" 2>/dev/null; then
        echo "GPG key already exists for $GPG_KEY_EMAIL"
        return 0
    fi
    
    # Generate new GPG key
    echo "Generating new GPG key..."
    cat > /tmp/gpg-keygen << EOF
%echo Generating NetSnmp Enterprise signing key...
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: $GPG_KEY_NAME
Name-Comment: $GPG_KEY_COMMENT
Name-Email: $GPG_KEY_EMAIL
Expire-Date: $GPG_EXPIRY
%commit
%echo Key generation complete!
EOF
    
    gpg --batch --generate-key /tmp/gpg-keygen
    rm -f /tmp/gpg-keygen
    
    # Export public key
    mkdir -p packaging/keys
    gpg --armor --export "$GPG_KEY_EMAIL" > packaging/keys/public-key.asc
    
    # Export private key (secured)
    echo "GPG_KEY: $(gpg --export-secret-keys --armor "$GPG_KEY_EMAIL" | base64 -w0)" > packaging/keys/private-key.asc
    
    echo "✅ GPG setup completed successfully!"
    echo "Public key: packaging/keys/public-key.asc"
}

sign_deb_package() {
    local package_file="$1"
    
    if [[ ! -f "$package_file" ]]; then
        echo "Error: Package file not found: $package_file"
        return 1
    fi
    
    echo "Signing Debian package: $package_file"
    
    # Create signature
    gpg --armor --detach-sign --output "${package_file}.asc" "$package_file"
    
    # Verify signature
    if gpg --verify "${package_file}.asc" "$package_file"; then
        echo "✅ Debian package signed successfully: ${package_file}.asc"
    else
        echo "❌ Debian package signing failed"
        return 1
    fi
}

sign_rpm_package() {
    local package_file="$1"
    
    if [[ ! -f "$package_file" ]]; then
        echo "Error: Package file not found: $package_file"
        return 1
    fi
    
    echo "Signing RPM package: $package_file"
    
    # Import key to RPM
    gpg --export --armor "$GPG_KEY_EMAIL" > /tmp/RPM-GPG-KEY-netsnmp
    rpm --import /tmp/RPM-GPG-KEY-netsnmp
    rm -f /tmp/RPM-GPG-KEY-netsnmp
    
    # Sign RPM package
    rpm --addsign --define "_gpg_name $GPG_KEY_EMAIL" "$package_file"
    
    # Verify signature
    if rpm --checksig "$package_file"; then
        echo "✅ RPM package signed successfully"
    else
        echo "❌ RPM package signing failed"
        return 1
    fi
}

export_gpg_to_github() {
    echo "Exporting GPG key for GitHub..."
    
    # Export private key for GitHub Secrets
    local private_key=$(gpg --export-secret-keys --armor "$GPG_KEY_EMAIL" | base64 -w0)
    local public_key=$(gpg --export --armor "$GPG_KEY_EMAIL" | base64 -w0)
    local key_id=$(gpg --list-secret-keys --keyid-format LONG "$GPG_KEY_EMAIL" | grep sec | awk '{print $2}' | cut -d'/' -f2)
    
    cat > packaging/keys/github-keys.txt << EOF
# Add these to GitHub Secrets:
GPG_PRIVATE_KEY: $private_key
GPG_PUBLIC_KEY: $public_key
GPG_KEY_ID: $key_id

# GitHub Actions usage:
# - name: Import GPG key
#   run: |
#     echo "$private_key" | base64 -d | gpg --import
#     gpg --list-secret-keys
EOF
    
    echo "✅ GitHub keys exported to: packaging/keys/github-keys.txt"
    echo "Please add these values to your GitHub repository secrets"
}

main() {
    case "$1" in
        setup)
            setup_gpg
            ;;
        sign-deb)
            sign_deb_package "$2"
            ;;
        sign-rpm)
            sign_rpm_package "$2"
            ;;
        github)
            export_gpg_to_github
            ;;
        *)
            echo "Usage: $0 {setup|sign-deb|sign-rpm|github}"
            echo "  setup      - Setup GPG signing keys"
            echo "  sign-deb   - Sign Debian package"
            echo "  sign-rpm   - Sign RPM package"
            echo "  github     - Export keys for GitHub"
            exit 1
            ;;
    esac
}

main "$@"