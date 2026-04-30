# Python tooling, Node.js 20 (NodeSource — Ubuntu 22.04's apt npm = Node 12,
# too old), and Google Chrome + CJK fonts for puppeteer PDF rendering.
# The dotfiles overlay later installs nvm with the latest LTS; both coexist
# and nvm takes precedence in interactive shells.

RUN apt-get update && apt-get install -y --no-install-recommends \
      gnupg python3-pip python3-venv \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

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
