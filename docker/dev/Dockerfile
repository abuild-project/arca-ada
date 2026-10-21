# SPDX-License-Identifier: BSD-3-Clause

FROM debian:trixie-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        gnat \
        gprbuild \
        make \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work
