# SPDX-License-Identifier: GPL-2.0-or-later

FROM debian:trixie-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        cpio \
        gcc \
        git \
        gnat \
        gprbuild \
        libahven-dev \
        libarchive-tools \
        make \
        mkdocs-material \
        python3 \
        tar \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work
