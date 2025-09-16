PREFIX ?= /usr
BINDIR ?= $(PREFIX)/bin
MANDIR ?= $(PREFIX)/share/man/man1
CONFDIR ?= /etc/netsnmp
CACHEDIR ?= /var/cache/netsnmp
LOGDIR ?= /var/log

VERSION = 2.0.0
BUILD_DATE = $(shell date +%Y-%m-%d)

.PHONY: all install uninstall clean test deb rpm arch snap flatpak setup-scripts

all: netsnmp installer

# Build the main executable by bundling all modules
netsnmp: src/core/main.sh
	@echo "Building NetSnmp Enterprise $(VERSION)"
	@cp src/core/main.sh netsnmp
	@chmod +x netsnmp
	@echo "Build complete: netsnmp"

setup-scripts:
	@echo "Setting up script permissions..."
	@chmod +x packaging/deb/build.sh
	@chmod +x packaging/rpm/build.sh
	@chmod +x packaging/arch/build.sh
	@chmod +x src/tests/*.sh
	@chmod +x scripts/*.sh 2>/dev/null || true

	@echo "Script permissions set"

install: netsnmp
	@echo "Installing NetSnmp Enterprise to $(DESTDIR)$(PREFIX)"
	@install -d $(DESTDIR)$(BINDIR)
	@install -d $(DESTDIR)$(MANDIR)
	@install -d $(DESTDIR)$(CONFDIR)
	@install -d $(DESTDIR)$(CACHEDIR)
	@install -m 755 netsnmp $(DESTDIR)$(BINDIR)/netsnmp
	@install -m 644 man/netsnmp.1 $(DESTDIR)$(MANDIR)/netsnmp.1
	@install -m 644 config/netsnmp.conf $(DESTDIR)$(CONFDIR)/netsnmp.conf
	@echo "Installation complete"

uninstall:
	@echo "Uninstalling NetSnmp Enterprise"
	@rm -f $(DESTDIR)$(BINDIR)/netsnmp
	@rm -f $(DESTDIR)$(MANDIR)/netsnmp.1.gz
	@rm -rf $(DESTDIR)$(CONFDIR)
	@rm -rf $(DESTDIR)$(CACHEDIR)
	@echo "Uninstall complete"

installer:
	@echo "Building installer..."
	@cat src/install/installer.sh > installer.tmp
	@for module in src/install/dependencies.sh src/install/postinstall.sh; do \
		sed '1d;$$d' $$module >> installer.tmp; \
	done
	@echo "main \"\$$@\"" >> installer.tmp
	@mv installer.tmp netsnmp-installer
	@chmod +x netsnmp-installer
	@echo "Installer built: netsnmp-installer"

install-system: netsnmp
	sudo ./netsnmp-installer --system

install-user: netsnmp
	./netsnmp-installer --user

test: setup-scripts
	@echo "Running tests..."
	@cd src/tests && ./run_tests.sh

packages: setup-scripts deb rpm arch

deb:
	@echo "Building Debian package..."
	@cd packaging/deb && ./build.sh

rpm:
	@echo "Building RPM package..."
	@cd packaging/rpm && ./build.sh

arch:
	@echo "Building Arch Linux package..."
	@cd packaging/arch && ./build.sh

snap:
	@echo "Building Snap package..."
	@cd packaging/snap && ./build.sh

flatpak:
	@echo "Building Flatpak package..."
	@cd packaging/flatpak && ./build.sh

clean-packages:
	@echo "Cleaning package artifacts..."
	@rm -f packaging/*/*.deb
	@rm -f packaging/*/*.rpm
	@rm -f packaging/*/*.pkg.tar.*
	@rm -f packaging/*/*.snap
	@rm -f packaging/*/*.flatpak
	@rm -f packaging/*/*.tar.gz
	@rm -rf packaging/deb/debian
	@rm -rf packaging/rpm/rpmbuild
	@rm -rf packaging/arch/{src,pkg}
	@rm -rf packaging/snap/{prime,stage,parts}
	@rm -rf packaging/flatpak/build-dir
	@rm -rf packaging/flatpak/.flatpak-builder

clean:
	@rm -f netsnmp
	@rm -f netsnmp-installer
	@echo "Clean complete"

release-patch:
	@./scripts/release-manager.sh patch

release-minor:
	@./scripts/release-manager.sh minor

release-major:
	@./scripts/release-manager.sh major

version:
	@./scripts/release-manager.sh version

gpg-setup:
	@./scripts/gpg-setup.sh setup

gpg-sign-deb:
	@./scripts/gpg-setup.sh sign-deb packaging/deb/*.deb

gpg-sign-rpm:
	@./scripts/gpg-setup.sh sign-rpm packaging/rpm/*.rpm

gpg-github:
	@./scripts/gpg-setup.sh github

ppa-source:
	@echo "Building source package for PPA..."
	@cd packaging/deb && PPA_MODE=true ./build.sh

ppa-configure:
	@echo "Configuring PPA..."
	@cd packaging/deb && ./../scripts/configure-ppa.sh $(VERSION)

# Release targets
release: clean test packages ppa-source
	@echo "Release build complete"

release-ppa: release
	@echo "PPA release package ready in packaging/deb/"
	
ppa-setup:
	@./scripts/setup-ppa.sh

ppa-upload:
	@if [ -z "$(PPA)" ]; then \
		echo "Usage: make ppa-upload PPA=ppa:your-username/netsnmp"; \
		exit 1; \
	fi
	@./scripts/upload-ppa.sh $(PPA)

# Repository distribution
setup-ppa:
	@./scripts/setup-ppa.sh

# CI/CD helpers
ci-build:
	@make clean
	@make
	@make test

ci-packages:
	@make deb
	@make rpm
	@make arch

ci-release:
	@make ci-build
	@make ci-packages
	@make gpg-sign-deb
	@make gpg-sign-rpm

.PHONY: version