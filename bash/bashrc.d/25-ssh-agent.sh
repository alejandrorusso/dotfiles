# Start ssh-agent once per session and reuse it across new shells.
#
# Plain `eval $(ssh-agent)` in every shell would spawn a new agent each time
# (orphan processes; keys you ssh-add don't carry across terminals). This
# version stashes the agent's env in ~/.ssh/agent.env and only starts a new
# agent when the cached one is missing or dead.

_SSH_AGENT_ENV="$HOME/.ssh/agent.env"

_ssh_agent_running() {
  [ -n "$SSH_AUTH_SOCK" ] && [ -S "$SSH_AUTH_SOCK" ] && \
    ssh-add -l >/dev/null 2>&1 || [ $? -eq 1 ]
  # exit 0 = agent reachable (keys loaded); exit 1 = reachable but empty;
  # exit 2 = unreachable — caller treats only exit 2 as "start a new one"
}

if command -v ssh-agent >/dev/null 2>&1; then
  # Try the cached env first.
  if [ -r "$_SSH_AGENT_ENV" ]; then
    # shellcheck disable=SC1090
    . "$_SSH_AGENT_ENV" >/dev/null
  fi

  # If no live agent is reachable, start a fresh one and cache its env.
  if ! ssh-add -l >/dev/null 2>&1 && [ $? -ne 1 ]; then
    mkdir -p "$(dirname "$_SSH_AGENT_ENV")"
    ssh-agent -s > "$_SSH_AGENT_ENV"
    # shellcheck disable=SC1090
    . "$_SSH_AGENT_ENV" >/dev/null
  fi
fi

unset _SSH_AGENT_ENV
