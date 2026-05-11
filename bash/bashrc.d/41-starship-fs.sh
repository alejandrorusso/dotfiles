# Swap STARSHIP_CONFIG based on the filesystem type of $PWD.
# On slow remote-ish filesystems (9p/drvfs Windows bind mounts) `git status`
# can take seconds; we point starship at a config that disables git_status
# in those directories so the prompt stays snappy.
#
# Detection runs at most once per cwd change (cached via $_starship_last_pwd),
# and `stat -f` is a cheap statvfs call even on 9p.

_starship_fs_select() {
  [ "$_starship_last_pwd" = "$PWD" ] && return
  _starship_last_pwd=$PWD
  case "$(stat -f -c %T . 2>/dev/null)" in
    9p|v9fs|drvfs|fuse.drvfs|fuseblk|cifs|nfs|nfs4|smbfs)
      export STARSHIP_CONFIG="$HOME/.config/starship-slow.toml" ;;
    *)
      export STARSHIP_CONFIG="$HOME/.config/starship.toml" ;;
  esac
}

# Prepend to PROMPT_COMMAND so the selection happens before starship_precmd.
case "$PROMPT_COMMAND" in
  *_starship_fs_select*) ;;
  *) PROMPT_COMMAND="_starship_fs_select;${PROMPT_COMMAND:-:}" ;;
esac
