# NetSnmp Enterprise Packaging Guide

## Package Formats Supported

### Debian/Ubuntu (.deb)

```bash
# Build Debian package
make deb

# Install locally
sudo dpkg -i packaging/deb/netsnmp-enterprise_2.0.0_all.deb
```

### RHEL/CentOS/Fedora (.rpm)

```bash
# Build RPM package
make rpm

# Install locally
sudo rpm -ivh packaging/rpm/netsnmp-enterprise-2.0.0-1.x86_64.rpm
```

### Arch Linux (.pkg.tar.zst)

```bash
# Build Arch package
make arch

# Install locally
sudo pacman -U packaging/arch/netsnmp-enterprise-2.0.0-1-any.pkg.tar.zst
```

### Snap Package

```bash
# Build Snap package
make snap

# Install locally
sudo snap install --dangerous packaging/snap/netsnmp-enterprise_2.0.0_amd64.snap
```

### Flatpak Package

```bash
# Build Flatpak package
make flatpak

# Install locally
flatpak install --bundle packaging/flatpak/netsnmp-enterprise.flatpak
```

## Building All Packages

```bash
# Build all package formats
make packages

# Clean package artifacts
make clean-packages
```

## Package Structure

### Debian/Ubuntu

* **Binary**: `/usr/bin/netsnmp`
* **Configuration**: `/etc/netsnmp/netsnmp.conf`
* **Cache**: `/var/cache/netsnmp`
* **Logs**: `/var/log/netsnmp.log`
* **Documentation**: `/usr/share/doc/netsnmp-enterprise/`

### RHEL/CentOS/Fedora

* **Binary**: `/usr/bin/netsnmp`
* **Configuration**: `/etc/netsnmp/netsnmp.conf`
* **Cache**: `/var/cache/netsnmp`
* **Documentation**: `/usr/share/doc/netsnmp-enterprise/`

### Arch Linux

* **Binary**: `/usr/bin/netsnmp`
* **Configuration**: `/etc/netsnmp/netsnmp.conf`
* **Cache**: `/var/cache/netsnmp`
* **Documentation**: `/usr/share/doc/netsnmp-enterprise/`

## Dependency Management

All packages automatically handle dependencies:

### Debian/Ubuntu

* `snmp`, `snmpd`, `iputils-ping`, `fping`, `parallel`, `curl`

### RHEL/CentOS/Fedora

* `net-snmp-utils`, `iputils`, `fping`, `parallel`, `curl`

### Arch Linux

* `net-snmp`, `iputils`, `fping`, `parallel`, `curl`

## Testing Packages

```bash
# Test all packages
cd packaging
./test-packages.sh
```

## Repository Distribution

### Debian/Ubuntu PPA

```bash
# Build for PPA
debuild -S -sa

# Upload to PPA
dput ppa:ky6/netsnmp ../netsnmp-enterprise_2.0.0-1_source.changes
```

### Fedora COPR

```bash
# Build SRPM
rpmbuild -bs packaging/rpm/netsnmp.spec

# Upload to COPR
copr-cli build netsnmp-enterprise ~/rpmbuild/SRPMS/netsnmp-enterprise-2.0.0-1.el8.src.rpm
```

### Arch Linux AUR

```bash
# Prepare AUR package
makepkg --source

# Upload to AUR
git clone ssh://aur@aur.archlinux.org/netsnmp-enterprise.git
cp PKGBUILD .SRCINFO netsnmp-enterprise/
cd netsnmp-enterprise
git add .
git commit -m "Release v2.0.0"
git push
```

## Signing Packages

### GPG Key Setup

```bash
# Generate GPG key
gpg --full-generate-key

# Export public key
gpg --export --armor safarikikandi@gmail.com > packaging/public-key.asc

# Sign Debian package
debsign -k YOUR_KEY_ID ../netsnmp-enterprise_2.0.0-1_source.changes

# Sign RPM package
rpm --addsign ~/rpmbuild/RPMS/x86_64/netsnmp-enterprise-2.0.0-1.el8.x86_64.rpm
```

## Continuous Integration

GitHub Actions automatically build packages on:

* Push to main branch
* Tag releases
* Pull requests

See `.github/workflows/packages.yml` for CI configuration.
