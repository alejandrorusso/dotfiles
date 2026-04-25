# MkDocs devcontainer — mkdocs + mkdocs-material + plugins, plus puppeteer
# and Google Chrome for PDF rendering via mkdocs-page-pdf.
#
# Node.js 20 is installed from NodeSource so puppeteer can be baked into the
# image. The dotfiles overlay later installs nvm with the latest LTS; both
# coexist and nvm takes precedence in interactive shells.

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git sudo locales gnupg \
      python3-pip python3-venv \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# Node.js 20 from NodeSource (Ubuntu 22.04's apt npm = Node 12, too old).
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# Google Chrome + CJK fonts for puppeteer PDF rendering.
RUN install -d /etc/apt/keyrings \
    && curl -fsSL https://dl-ssl.google.com/linux/linux_signing_key.pub \
       | gpg --dearmor -o /etc/apt/keyrings/google-linux.gpg \
    && echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-linux.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
       > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update && apt-get install -y --no-install-recommends \
      google-chrome-stable \
      fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf \
      libxss1 dbus-x11 \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash vscode \
    && echo "vscode ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/vscode \
    && chmod 0440 /etc/sudoers.d/vscode

USER vscode
WORKDIR /home/vscode

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
