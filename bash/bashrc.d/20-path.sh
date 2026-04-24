# Put local bins and Haskell toolchain on PATH if present.
# GHCup / cabal paths are harmless when absent; the devcontainer provides them.
for d in "$HOME/bin" "$HOME/.local/bin" "$HOME/.cabal/bin" "$HOME/.ghcup/bin" "/opt/nvim-linux-x86_64/bin"; do
  [ -d "$d" ] && case ":$PATH:" in *":$d:"*) ;; *) PATH="$d:$PATH" ;; esac
done
export PATH
