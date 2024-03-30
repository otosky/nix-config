#! /usr/bin/fish

function git_current_branch
  set -l ref $(GIT_OPTIONAL_LOCKS=0 git symbolic-ref --quiet HEAD 2> /dev/null)
  set -l ret $status

  if test $ret -ne 0
    test $ret -eq 128 && return  # no git repo.
    set -l ref $(GIT_OPTIONAL_LOCKS=0 git rev-parse --short HEAD 2> /dev/null) || return
  end
  
  echo (string replace refs/heads/ '' $ref)
end
