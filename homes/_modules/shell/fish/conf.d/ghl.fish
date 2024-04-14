#! /usr/bin/fish

function ghl -d "List Github repos with fzf and go to selected repo in browser."
  set -f selected (gh repo list | fzf | cut -f 1)

  if test -n "$selected"
    gh repo view --web "$selected"
  end
end
