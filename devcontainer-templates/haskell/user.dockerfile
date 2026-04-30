# Haskell toolchain pinned to engine-v2's versions: GHC 9.12.2 / Cabal 3.16.0.0
# / HLS recommended, plus hlint, fourmolu, cabal-gild, fast-tags, and hoogle
# (built from source). Override versions at build time with --build-arg.

ARG GHC_VERSION=9.12.2
ARG CABAL_VERSION=3.16.0.0
ARG HLS_VERSION=recommended

ENV BOOTSTRAP_HASKELL_NONINTERACTIVE=1 \
    BOOTSTRAP_HASKELL_GHC_VERSION=${GHC_VERSION} \
    BOOTSTRAP_HASKELL_CABAL_VERSION=${CABAL_VERSION} \
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
