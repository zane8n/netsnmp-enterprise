#!/bin/bash
# PPA upload script

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <ppa-name>"
    echo "Example: $0 ppa:ky6/netsnmp-enterprise"
    exit 1
fi

PPA_NAME=$1

echo "Uploading to PPA: $PPA_NAME"

# Check if source changes file exists
if [[ ! -f packaging/deb/../netsnmp-enterprise_2.0.0-1_source.changes ]]; then
    echo "Source package not found. Building first..."
    ./scripts/setup-ppa.sh
fi

# Upload to PPA
cd packaging/deb/..
dput $PPA_NAME netsnmp-enterprise_2.0.0-1_source.changes

echo "✅ Uploaded to PPA successfully"
echo "Check status at: https://launchpad.net/~${PPA_NAME#ppa:}"