#!/usr/bin/env bash
_shipgo_complete() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local cmds="push p up first all tags force f dry dry-run del rm remote to undo
    sync pull fetch prune amend cleanup
    tag tag-list tag-del release
    pr draft-pr mr
    status st info log branches ahead behind whoami doctor ping open compare
    config init-config
    wip stash stash-pop init clone menu help version"
  COMPREPLY=($(compgen -W "$cmds" -- "$cur"))
}
complete -F _shipgo_complete shipgo