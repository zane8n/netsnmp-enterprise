# NetSnmp Enterprise

![NetSnmp Enterprise](https://img.shields.io/badge/NetSnmp-Enterprise-blue)
![Version](https://img.shields.io/badge/version-2.0.0-green)
![License](https://img.shields.io/badge/license-GPL--3.0-orange)
![Platform](https://img.shields.io/badge/platform-Linux-lightgrey)

Enterprise-grade network discovery and inventory tool for Linux systems. Discover, monitor, and manage network devices using ICMP and SNMP protocols with unparalleled efficiency.

## 🚀 Features

* **Multi-Protocol Discovery**: ICMP ping combined with SNMP for comprehensive device detection
* **Cross-Platform Support**: Works on Debian, Ubuntu, RHEL, CentOS, Arch, and other Linux distributions
* **Intelligent Caching**: Smart caching system with configurable TTL for rapid searches
* **Parallel Scanning**: Multi-threaded scanning for large network environments
* **Flexible Network Formats**: Support for CIDR, IP ranges, and single IP addresses
* **Comprehensive Testing**: Built-in validation and testing utilities
* **Enterprise Ready**: Robust error handling and logging capabilities

## 📦 Installation

### Quick Install (From Source)

```bash
git clone https://github.com/zane8n/netsnmp-enterprise
cd netsnmp-enterprise
sudo make install
```

### Package Manager Installation (Coming Soon)

```bash
# Debian/Ubuntu
sudo apt install netsnmp-enterprise

# RHEL/CentOS
sudo yum install netsnmp-enterprise

# Arch Linux
sudo pacman -S netsnmp-enterprise
```

## 🎯 Quick Start

**First-Time Setup:**

```bash
sudo netsnmp --wizard
```

**Scan Your Network:**

```bash
sudo netsnmp --update
```

**Search for Devices:**

```bash
netsnmp switch      # Find all switches
netsnmp router      # Find all routers
netsnmp 192.168.1   # Find devices in specific subnet
```

## 📖 Usage Examples

### Basic Operations

```bash
# Scan network and update cache
netsnmp --update

# Show cache information
netsnmp --info

# Search for specific devices
netsnmp firewall
netsnmp server
netsnmp 10.0.0.50

# Scan single device
netsnmp --scan 192.168.1.1
```

### Advanced Configuration

```bash
# Use custom networks
netsnmp --networks "192.168.1.0/24 10.0.0.1-100" --update

# Use custom SNMP communities
netsnmp --communities "public private admin" --update

# Verbose output for debugging
netsnmp --verbose --update
```

### Testing and Validation

```bash
# Test IP generation
netsnmp --test-ips 192.168.1.1-10

# Test SNMP connectivity
netsnmp --test-snmp 192.168.1.1

# Run comprehensive scan test
netsnmp --test-scan
```

## ⚙️ Configuration

NetSnmp Enterprise uses a simple configuration file format:

```ini
# Networks to scan (space separated)
subnets="192.168.1.0/24 10.0.0.0/24"

# SNMP communities to try
communities="public private"

# Timeout settings (seconds)
ping_timeout="1"
snmp_timeout="2"

# Performance settings
scan_workers="10"
cache_ttl="3600"

# Logging
enable_logging="true"
```

**Configuration Locations:**

* System-wide: `/etc/netsnmp/netsnmp.conf`
* User-specific: `~/.config/netsnmp/netsnmp.conf`

## 🏗️ Architecture

```text
NetSnmp Enterprise/
├── Core Modules/
│   ├── config.sh      # Configuration management
│   ├── scanner.sh     # Network scanning logic
│   ├── cache.sh       # Cache system
│   ├── utils.sh       # Utility functions
│   └── logging.sh     # Logging system
├── Installation/
│   ├── installer.sh   # Main installer
│   └── dependencies.sh # Package management
└── Tests/
    └── test_*.sh      # Comprehensive test suite
```

## 🔧 Development

### Building from Source

```bash
# Clone repository
git clone https://github.com/zane8n/netsnmp-enterprise
cd netsnmp-enterprise

# Build the application
make

# Install system-wide
sudo make install

# Run tests
make test
```

### Contributing

We welcome contributions! Please see our:

* [Contributing Guide](CONTRIBUTING.md)
* [Code of Conduct](CODE_OF_CONDUCT.md)
* [Development Documentation](docs/)

## 📊 Performance

* **Scan Speed**: \~1000 devices/minute (depending on hardware)
* **Memory Usage**: < 50MB during operation
* **Cache Efficiency**: Sub-millisecond search responses
* **Network Impact**: Configurable parallel workers to control bandwidth usage

## 🐛 Troubleshooting

### Common Issues

**Permission Errors:**

```bash
sudo netsnmp --update
```

**SNMP Timeouts:**

```bash
netsnmp --test-snmp <DEVICE_IP>
```

**Cache Issues:**

```bash
netsnmp --clear
netsnmp --update
```

### Debug Mode

For detailed debugging:

```bash
netsnmp --debug --update
```

## 📝 License

NetSnmp Enterprise is licensed under the GNU General Public License v3.0 - see the LICENSE file for details.

## 🤝 Support

* **Documentation**: [API Reference](https://github.com/zane8n/netsnmp-enterprise/docs/api.md)
* **Issues**: [GitHub Issues](https://github.com/zane8n/netsnmp-enterprise/issues)
* **Discussions**: [GitHub Discussions](https://github.com/zane8n/netsnmp-enterprise/discussions)
* **Email**: [safarikikandi@gmail.com](mailto:safarikikandi@gmail.com)

## 🚀 Roadmap

* Docker container support
* REST API interface
* Web dashboard
* Database integration
* Alerting system
* Plugin architecture

---

**NetSnmp Enterprise** - Your network, discovered. Your inventory, managed. Your infrastructure, understood.

Built with ❤️ for network professionals and system administrators.
