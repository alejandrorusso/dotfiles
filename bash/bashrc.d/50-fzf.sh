export FZF_DEFAULT_OPTS="--preview 'batcat -p --color=always {} | head -500'"
command -v fzf >/dev/null 2>&1 && eval "$(fzf --bash)"
