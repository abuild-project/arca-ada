# SPDX-License-Identifier: BSD-3-Clause

NUM_CPUS ?= 8
PREFIX ?= $(CURDIR)/build/install
GPRBUILD ?= gprbuild
GPRINSTALL ?= gprinstall
GPRCLEAN ?= gprclean

.PHONY: all check install clean preflight

all: preflight
	$(GPRBUILD) -p -P arca.gpr -j$(NUM_CPUS)

check: all
	+MAKE="$(MAKE)" ./tests/check-preflight.sh
	$(GPRBUILD) -p -P examples/client/client.gpr -aP. -j$(NUM_CPUS)
	./examples/client/bin/arca_client
	GPRBUILD="$(GPRBUILD)" GPRINSTALL="$(GPRINSTALL)" \
		NUM_CPUS="$(NUM_CPUS)" ./tests/check-install.sh

install: all
	$(GPRINSTALL) -p -P arca.gpr --prefix="$(PREFIX)"

clean:
	$(GPRCLEAN) -P examples/client/client.gpr -aP.
	$(GPRCLEAN) -P arca.gpr

preflight:
	GPRBUILD="$(GPRBUILD)" GPRINSTALL="$(GPRINSTALL)" \
		GPRCLEAN="$(GPRCLEAN)" ./scripts/check-tools.sh
