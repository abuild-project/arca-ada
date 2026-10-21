# SPDX-License-Identifier: LGPL-2.1-or-later

FROM debian:trixie-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        gnat \
        gprbuild \
        make \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work
