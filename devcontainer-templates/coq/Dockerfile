# Coq devcontainer.
#
# Installs Coq 8.20.1 + coq-lsp 0.2.5 (matched server/version) via opam.
# Override versions at build time with --build-arg.

FROM ubuntu:22.04

ARG OCAML_VERSION=4.14.2
ARG COQ_VERSION=8.20.1
ARG COQ_LSP_VERSION=0.2.5+8.20
ARG OPAM_SWITCH=cloudchor

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git sudo locales \
      build-essential opam pkg-config m4 unzip \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash vscode \
    && echo "vscode ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/vscode \
    && chmod 0440 /etc/sudoers.d/vscode

USER vscode
WORKDIR /home/vscode

# Initialise opam, create a switch with the chosen OCaml, then install
# Coq + coq-lsp from the coq-released repo. --disable-sandboxing is
# required inside containers (no bwrap available).
RUN opam init --bare --no-setup --disable-sandboxing --yes \
    && opam switch create ${OPAM_SWITCH} ${OCAML_VERSION} --yes \
    && opam repo add coq-released https://coq.inria.fr/opam/released \
         --switch ${OPAM_SWITCH} --yes \
    && opam install --switch ${OPAM_SWITCH} --yes --assume-depexts \
         coq.${COQ_VERSION} coq-lsp.${COQ_LSP_VERSION} \
    && opam clean --all-switches --download-cache --logs --repo-cache --yes

# Expose the Coq toolchain on the default PATH so nvim's LSP client and
# any non-login shell (incl. CI) can find them without sourcing opam env.
# coqdep and coq_makefile are needed for projects with a _CoqProject /
# Makefile (the standard layout); coqc/coqtop/coq-lsp are the daily drivers.
RUN sudo ln -sf /home/vscode/.opam/${OPAM_SWITCH}/bin/coqc         /usr/local/bin/coqc \
    && sudo ln -sf /home/vscode/.opam/${OPAM_SWITCH}/bin/coqtop      /usr/local/bin/coqtop \
    && sudo ln -sf /home/vscode/.opam/${OPAM_SWITCH}/bin/coq-lsp     /usr/local/bin/coq-lsp \
    && sudo ln -sf /home/vscode/.opam/${OPAM_SWITCH}/bin/coqdep      /usr/local/bin/coqdep \
    && sudo ln -sf /home/vscode/.opam/${OPAM_SWITCH}/bin/coq_makefile /usr/local/bin/coq_makefile \
    && sudo ln -sf /home/vscode/.opam/${OPAM_SWITCH}/bin/coqdoc      /usr/local/bin/coqdoc \
    && sudo ln -sf /home/vscode/.opam/${OPAM_SWITCH}/bin/coqchk      /usr/local/bin/coqchk

# Activate the switch in interactive shells (so `opam` itself works).
RUN echo "eval \"\$(opam env --switch=${OPAM_SWITCH} 2>/dev/null)\"" >> /home/vscode/.bashrc
