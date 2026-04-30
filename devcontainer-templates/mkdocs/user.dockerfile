ENV PATH="/home/vscode/.local/bin:${PATH}"

RUN python3 -m pip install --user --upgrade Pygments \
    && python3 -m pip install --user \
      pymdown-extensions \
      mkdocs \
      mkdocs-material \
      mkdocs-include-markdown-plugin \
      mkdocs-excel-plugin \
      mkdocs-page-pdf

RUN mkdir -p /home/vscode/.mkdocs-deps \
    && cd /home/vscode/.mkdocs-deps \
    && npm init -y >/dev/null \
    && npm install puppeteer
