# SPDX-License-Identifier: GPL-2.0-or-later

NUM_CPUS ?= 8
PREFIX ?= $(CURDIR)/build/install
GPRBUILD ?= gprbuild
GPRINSTALL ?= gprinstall
GPRCLEAN ?= gprclean
MKDOCS ?= mkdocs

.PHONY: all cli check coverage docs install uninstall clean preflight

all: preflight
	"$(GPRBUILD)" -p -P arca.gpr -j$(NUM_CPUS) -XARCA_BUILD_MODE=validation
	"$(GPRBUILD)" -p -P cli/cli.gpr -aP. -j$(NUM_CPUS) -XARCA_BUILD_MODE=validation

cli: preflight
	"$(GPRBUILD)" -p -P cli/cli.gpr -aP. -j$(NUM_CPUS) -XARCA_BUILD_MODE=validation

check: all
	./scripts/check-test-tools.sh
	./tests/check-style.py --builder "$(GPRBUILD)" --jobs "$(NUM_CPUS)"
	+./tests/check-packaging.py --builder "$(GPRBUILD)" --cleaner "$(GPRCLEAN)" \
		--make-command "$(MAKE)" --jobs "$(NUM_CPUS)"
	+MAKE="$(MAKE)" ./tests/check-preflight.sh
	+MAKE="$(MAKE)" NUM_CPUS="$(NUM_CPUS)" ./tests/check-make-tools.sh
	"$(GPRBUILD)" -p -P examples/client/client.gpr -aP. -j$(NUM_CPUS) \
		-XARCA_BUILD_MODE=validation
	./examples/client/bin/arca_client
	"$(GPRBUILD)" -p -P tests/tests.gpr -j$(NUM_CPUS) -XARCA_BUILD_MODE=validation
	./tests/check-api.py --builder "$(GPRBUILD)" --installer "$(GPRINSTALL)" \
		--jobs "$(NUM_CPUS)"
	+MAKE="$(MAKE)" GPRBUILD="$(GPRBUILD)" GPRINSTALL="$(GPRINSTALL)" \
		GPRCLEAN="$(GPRCLEAN)" NUM_CPUS="$(NUM_CPUS)" ./tests/check-install.sh
	+MAKE="$(MAKE)" GPRBUILD="$(GPRBUILD)" GPRINSTALL="$(GPRINSTALL)" \
		GPRCLEAN="$(GPRCLEAN)" NUM_CPUS="$(NUM_CPUS)" ./tests/check-install-tools.sh
	./tests/check-unit.py
	./tests/check-cpio.py
	./tests/check-tar.py
	./tests/check-vfat-reference.py
	./tests/check-cli.py

coverage: preflight
	./scripts/check-test-tools.sh
	./tests/check-coverage.py --builder "$(GPRBUILD)" --jobs "$(NUM_CPUS)"

docs:
	python3 scripts/build-docs-site.py
	"$(MKDOCS)" build --strict

install: all
	"$(GPRINSTALL)" -p -P arca.gpr --prefix="$(PREFIX)" -XARCA_BUILD_MODE=validation
	"$(GPRINSTALL)" -p -P cli/cli.gpr -aP. --prefix="$(PREFIX)" \
		--mode=usage --no-project --install-name=arca-cli -XARCA_BUILD_MODE=validation

uninstall:
	"$(GPRINSTALL)" --uninstall --prefix="$(PREFIX)" arca-cli
	"$(GPRINSTALL)" --uninstall --prefix="$(PREFIX)" arca

clean:
	rm -rf -- tests/obj tests/bin tests/obj-coverage tests/bin-coverage
	"$(GPRCLEAN)" -P examples/client/client.gpr -aP. -XARCA_BUILD_MODE=validation
	"$(GPRCLEAN)" -P cli/cli.gpr -aP. -XARCA_BUILD_MODE=validation
	"$(GPRCLEAN)" -P cli/cli.gpr -aP. -XARCA_CLI_COVERAGE=enabled \
		-XARCA_BUILD_MODE=validation
	"$(GPRCLEAN)" -P arca.gpr -XARCA_BUILD_MODE=validation

preflight:
	GPRBUILD="$(GPRBUILD)" GPRINSTALL="$(GPRINSTALL)" \
		GPRCLEAN="$(GPRCLEAN)" ./scripts/check-tools.sh
