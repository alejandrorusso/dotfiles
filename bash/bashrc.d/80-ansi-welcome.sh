# Random ANSI welcome banner (only if the repo has been cloned).
if [ -d "$HOME/.ansi-welcome" ] && [ -x "$HOME/.ansi-welcome/random-ansi.sh" ]; then
  ( cd "$HOME/.ansi-welcome" && ./random-ansi.sh --cache )
fi
