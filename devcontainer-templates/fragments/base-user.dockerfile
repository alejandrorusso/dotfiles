# Base user — runs after all stacks' root.dockerfile fragments. Creates the
# vscode user and switches the build to it; everything in stacks' user.dockerfile
# fragments runs after this, as vscode.

RUN useradd -m -s /bin/bash vscode \
    && echo "vscode ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/vscode \
    && chmod 0440 /etc/sudoers.d/vscode

USER vscode
WORKDIR /home/vscode
