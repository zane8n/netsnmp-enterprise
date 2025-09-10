# NetSnmp Enterprise Installation Guide

## Quick Installation

### System-wide Installation (Recommended)

```bash
git clone https://github.com/zane8n/netsnmp-enterprise
cd netsnmp-enterprise
sudo make install-system
```

### User-specific Installation

```bash
git clone https://github.com/zane8n/netsnmp-enterprise
cd netsnmp-enterprise
make install-user
```

### Manual Installation

#### From Source

```bash
# Clone the repository
git clone https://github.com/zane8n/netsnmp-enterprise
cd netsnmp-enterprise

# Build the binary
make

# Install manually
sudo cp netsnmp /usr/bin/
sudo mkdir -p /etc/netsnmp
sudo cp config/netsnmp.conf /etc/netsnmp/
sudo cp man/netsnmp.1 /usr/share/man/man1/
sudo gzip /usr/share/man/man1/netsnmp.1
```

## Dependencies

NetSnmp Enterprise requires the following packages:

**Required:**

* `snmp` or `net-snmp-utils` - SNMP tools
* `iputils-ping` or `iputils` - Ping utilities

**Recommended:**

* `fping` - Parallel ping utility
* `parallel` - GNU parallel for efficient scanning

## Verification

After installation, verify the installation:

```bash
# Check version
netsnmp --version

# Test configuration
netsnmp --config

# Run a test scan
netsnmp --test-scan
```

## Uninstallation

### Using Uninstall Script

```bash
sudo netsnmp --uninstall-script | sudo bash
```

### Manual Uninstallation

```bash
sudo rm -f /usr/bin/netsnmp
sudo rm -f /usr/share/man/man1/netsnmp.1.gz
sudo rm -rf /etc/netsnmp
sudo rm -rf /var/cache/netsnmp
sudo rm -f /var/log/netsnmp.log
```

## Troubleshooting

### Permission Issues

If you encounter permission issues, ensure you're running with `sudo` for system-wide installation.

### Missing Dependencies

Install required dependencies for your distribution:

**Debian/Ubuntu:**

```bash
sudo apt install snmp snmpd iputils-ping fping parallel
```

**RHEL/CentOS/Fedora:**

```bash
sudo dnf install net-snmp net-snmp-utils iputils fping parallel
```

**Arch Linux:**

```bash
sudo pacman -S net-snmp iputils fping parallel
```

**openSUSE:**

```bash
sudo zypper install net-snmp iputils fping parallel
```

### Network Issues

Ensure your network configuration allows ICMP ping and SNMP traffic on the specified networks.
