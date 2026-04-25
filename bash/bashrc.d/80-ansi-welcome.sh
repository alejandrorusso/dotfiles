# Random ANSI welcome banner (only if the repo has been cloned, 30% of the time).
if [ -d "$HOME/.ansi-welcome" ] && [ -x "$HOME/.ansi-welcome/random-ansi.sh" ] && [ $((RANDOM % 100)) -lt 30 ]; then
  ( cd "$HOME/.ansi-welcome" && ./random-ansi.sh --cache )
fi
