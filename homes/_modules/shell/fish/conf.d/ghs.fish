#! /usr/bin/fish

function ghs -d "Search for a github repo and visit in browser."
  test -n "$argv" || gh search repos || return

  set -f selected (gh search repos $argv | fzf | cut -f 1)

  if test -n "$selected"
    gh repo view --web "$selected"
  end
end
