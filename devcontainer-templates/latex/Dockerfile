# LaTeX devcontainer — texlive (xetex/luatex/science/extra), latexmk, biber,
# lhs2tex, plus zathura/evince/inkscape/pdftk for previews and graphics.
#
# Mason texlab + ltex-ls are NOT pre-installed (they belong to nvim setup);
# run :MasonInstall ltex-ls texlab once after first launch.

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8

RUN echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" \
      | debconf-set-selections \
    && apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git sudo locales \
      texlive-xetex texlive-luatex texlive-science \
      texlive-extra-utils texlive-bibtex-extra texlive-fonts-extra \
      latexmk biber lhs2tex \
      zathura python3-pygments ttf-mscorefonts-installer \
      pdftk evince inkscape \
      default-jre-headless \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash vscode \
    && echo "vscode ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/vscode \
    && chmod 0440 /etc/sudoers.d/vscode

USER vscode
WORKDIR /home/vscode
