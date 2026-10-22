# SPDX-License-Identifier: LGPL-2.1-or-later

NUM_CPUS ?= 8
PREFIX ?= $(CURDIR)/build/install
GPRBUILD ?= gprbuild
GPRINSTALL ?= gprinstall
GPRCLEAN ?= gprclean

.PHONY: all check coverage install clean preflight

all: preflight
	"$(GPRBUILD)" -p -P arca.gpr -j$(NUM_CPUS)

check: all
	./scripts/check-test-tools.sh
	+MAKE="$(MAKE)" ./tests/check-preflight.sh
	+MAKE="$(MAKE)" NUM_CPUS="$(NUM_CPUS)" ./tests/check-make-tools.sh
	"$(GPRBUILD)" -p -P examples/client/client.gpr -aP. -j$(NUM_CPUS)
	./examples/client/bin/arca_client
	GPRBUILD="$(GPRBUILD)" GPRINSTALL="$(GPRINSTALL)" \
		NUM_CPUS="$(NUM_CPUS)" ./tests/check-install.sh
	GPRBUILD="$(GPRBUILD)" GPRINSTALL="$(GPRINSTALL)" \
		NUM_CPUS="$(NUM_CPUS)" ./tests/check-install-tools.sh
	"$(GPRBUILD)" -p -P tests/tests.gpr -j$(NUM_CPUS)
	./tests/check-cpio.py
	./tests/check-tar.py

coverage: preflight
	./scripts/check-test-tools.sh
	./tests/check-coverage.py --builder "$(GPRBUILD)" --jobs "$(NUM_CPUS)"

install: all
	"$(GPRINSTALL)" -p -P arca.gpr --prefix="$(PREFIX)"

clean:
	"$(GPRCLEAN)" -P tests/tests.gpr
	"$(GPRCLEAN)" -P tests/tests.gpr -XARCA_COVERAGE=enabled
	"$(GPRCLEAN)" -P examples/client/client.gpr -aP.
	"$(GPRCLEAN)" -P arca.gpr

preflight:
	GPRBUILD="$(GPRBUILD)" GPRINSTALL="$(GPRINSTALL)" \
		GPRCLEAN="$(GPRCLEAN)" ./scripts/check-tools.sh
