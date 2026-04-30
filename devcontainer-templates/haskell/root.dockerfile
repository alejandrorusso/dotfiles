# GHC build deps (libgmp/libnuma/zlib/liblzma) — required to bootstrap GHC
# via ghcup in the user fragment.

RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential libnuma-dev zlib1g-dev libgmp-dev libgmp10 liblzma-dev \
    && rm -rf /var/lib/apt/lists/*
