# SPDX-License-Identifier: LGPL-2.1-or-later

FROM debian:trixie-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        cpio \
        gcc \
        git \
        gnat \
        gprbuild \
        libarchive-tools \
        make \
        python3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work
