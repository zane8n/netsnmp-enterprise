Name: netsnmp-enterprise
Version: 2.0.0
Release: 1%{?dist}
Summary: Enterprise-grade network discovery tool
License: GPL-3.0
URL: https://github.com/zane8n/netsnmp-enterprise
Source0: %{name}-%{version}.tar.gz
BuildArch: noarch
Requires: net-snmp-utils, iputils, fping, parallel, curl

%description
NetSnmp Enterprise is a powerful network device discovery tool that uses
ICMP ping and SNMP protocols to discover and inventory network devices.

Features:
- Multi-protocol discovery (ICMP + SNMP)
- Cross-platform support
- Comprehensive caching system
- Parallel scanning capabilities
- Automated network inventory

%prep
%setup -q

%build
make

%install
rm -rf %{buildroot}
make install DESTDIR=%{buildroot}

# Install documentation
mkdir -p %{buildroot}/%{_docdir}/%{name}
install -m 644 docs/INSTALL.md %{buildroot}/%{_docdir}/%{name}/
install -m 644 README.md %{buildroot}/%{_docdir}/%{name}/

%files
%{_bindir}/netsnmp
%{_mandir}/man1/netsnmp.1.gz
%config(noreplace) %{_sysconfdir}/netsnmp/netsnmp.conf
%dir %{_localstatedir}/cache/netsnmp
%{_docdir}/%{name}/INSTALL.md
%{_docdir}/%{name}/README.md

%post
#!/bin/bash
# Post-installation script
echo "NetSnmp Enterprise post-installation setup..."

# Create directories
mkdir -p /etc/netsnmp
mkdir -p /var/cache/netsnmp
mkdir -p /var/log

# Set permissions
chmod 755 /var/cache/netsnmp
chmod 755 /etc/netsnmp

# Create default config if it doesn't exist
if [ ! -f /etc/netsnmp/netsnmp.conf ]; then
    cat > /etc/netsnmp/netsnmp.conf << 'EOF'
# NetSnmp Enterprise Configuration
subnets="192.168.1.0/24 10.0.0.0/24"
communities="public private"
ping_timeout="1"
snmp_timeout="2"
scan_workers="10"
cache_ttl="3600"
enable_logging="true"
EOF
    chmod 644 /etc/netsnmp/netsnmp.conf
fi

# Create log file
touch /var/log/netsnmp.log
chmod 644 /var/log/netsnmp.log

echo "Post-installation setup completed successfully!"

%preun
#!/bin/bash
# Pre-uninstallation script
if [ $1 -eq 0 ]; then
    # Package removal, not upgrade
    echo "Stopping NetSnmp services..."
    systemctl stop netsnmp.timer 2>/dev/null || true
    systemctl disable netsnmp.timer 2>/dev/null || true
fi

%postun
#!/bin/bash
# Post-uninstallation script
if [ $1 -ge 1 ]; then
    # Package upgrade, not removal
    systemctl daemon-reload 2>/dev/null || true
fi

%changelog
* $(date +"%a %b %d %Y") NetSnmp Team <safarikikandi@gmail.com> - 2.0.0-1
- Initial RPM package release