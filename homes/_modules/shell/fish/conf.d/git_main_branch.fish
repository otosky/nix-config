#! /usr/bin/fish

# https://github.com/jhillyerd/plugin-git/blob/master/functions/__git.default_branch.fish
function git_main_branch -d "Use the first existing branch: init.defaultBranch, main, master."
  command git rev-parse --git-dir &>/dev/null || return

  if set -l default_branch (command git config --get init.defaultBranch) && command git show-ref -q --verify refs/heads/{$default_branch}
    echo $default_branch
  else if command git show-ref -q --verify refs/heads/main
    echo main
  else
    echo master
  end
end
