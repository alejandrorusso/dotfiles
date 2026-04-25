# Haskell devcontainer — pinned to engine-v2's toolchain.
#
# GHC 9.12.2 / Cabal 3.16.0.0 / HLS recommended, plus hlint, fourmolu,
# cabal-gild, fast-tags, and hoogle (built from source). Override versions
# at build time with --build-arg.

FROM ubuntu:22.04

ARG GHC_VERSION=9.12.2
ARG CABAL_VERSION=3.16.0.0
ARG HLS_VERSION=recommended

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git sudo locales \
      build-essential libnuma-dev zlib1g-dev libgmp-dev libgmp10 liblzma-dev \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash vscode \
    && echo "vscode ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/vscode \
    && chmod 0440 /etc/sudoers.d/vscode

USER vscode
WORKDIR /home/vscode

ENV BOOTSTRAP_HASKELL_NONINTERACTIVE=1 \
    BOOTSTRAP_HASKELL_GHC_VERSION=${GHC_VERSION} \
    BOOTSTRAP_HASKELL_CABAL_VERSION=${CABAL_VERSION} \
    BOOTSTRAP_HASKELL_INSTALL_HLS=1 \
    BOOTSTRAP_HASKELL_ADJUST_BASHRC=N

RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh

ENV PATH="/home/vscode/.ghcup/bin:/home/vscode/.cabal/bin:${PATH}"

RUN ghcup install hls ${HLS_VERSION} && ghcup set hls ${HLS_VERSION}

RUN cabal update \
    && cabal install fast-tags hlint fourmolu cabal-gild \
    && rm -rf /home/vscode/.cabal/store/*/incoming /home/vscode/.cabal/logs

# hoogle: build from source (workaround for a long-standing upstream packaging bug
# in the Hackage release), then generate the local index.
RUN cd /tmp \
    && git clone --depth 1 https://github.com/ndmitchell/hoogle.git \
    && ( cd hoogle && cabal install ) \
    && rm -rf hoogle \
    && hoogle generate
