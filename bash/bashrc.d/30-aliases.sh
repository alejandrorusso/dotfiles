# Modern CLI replacements — each guarded so the alias only appears if the tool is installed.
command -v eza    >/dev/null 2>&1 && alias ls='eza --icons --git -a' && alias ll='eza -l --icons --git -a'
command -v batcat >/dev/null 2>&1 && alias less='batcat -p'
