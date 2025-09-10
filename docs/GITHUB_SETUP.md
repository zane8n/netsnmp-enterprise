# GitHub Setup Guide

## Required Secrets

Add these secrets to your GitHub repository:

### GPG Signing
- `GPG_PRIVATE_KEY`: Base64-encoded GPG private key
- `GPG_PASSPHRASE`: Passphrase for GPG key
- `GPG_KEY_ID`: GPG key ID

### Package Repositories
- `COPR_API_TOKEN`: Fedora COPR API token
- `AUR_SSH_KEY`: SSH private key for AUR access
- `LAUNCHPAD_API_TOKEN`: Launchpad PPA API token

### Notifications
- `SLACK_WEBHOOK`: Slack webhook URL for notifications

## GPG Key Setup

1. Generate GPG key:
```bash
./scripts/gpg-setup.sh setup