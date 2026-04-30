# texlive (xetex/luatex/science/extra), latexmk, biber, lhs2tex, plus
# zathura/evince/inkscape/pdftk for previews and graphics. Mason texlab +
# ltex-ls are NOT pre-installed (they belong to nvim setup); run
# :MasonInstall ltex-ls texlab once after first launch.

RUN echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" \
      | debconf-set-selections \
    && apt-get update && apt-get install -y --no-install-recommends \
      texlive-xetex texlive-luatex texlive-science \
      texlive-extra-utils texlive-bibtex-extra texlive-fonts-extra \
      latexmk biber lhs2tex \
      zathura python3-pygments ttf-mscorefonts-installer \
      pdftk evince inkscape \
      default-jre-headless \
    && rm -rf /var/lib/apt/lists/*
