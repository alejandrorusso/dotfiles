# Auto-attach to a tmux "main" session for interactive shells.
# Skip when:
#   - already inside tmux ($TMUX set)
#   - non-interactive shell (no `i` in $-)
#   - tmux not installed
#   - opted out via TMUX_OFF=1
if [ -z "$TMUX" ] \
  && [[ $- == *i* ]] \
  && [ -z "$TMUX_OFF" ] \
  && command -v tmux >/dev/null 2>&1; then
  exec tmux -u new-session -A -s main
fi
