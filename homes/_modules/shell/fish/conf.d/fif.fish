#! /usr/bin/fish

function fif 
  if test (count $argv) -lt 1 
    echo "fif: Need a string to search for!" && return 1
  end

  set -l cmd 'bat --color always --style=numbers --line-range=:500 {}'

  rg --files-with-matches --no-messages $argv[1] | fzf --preview $cmd
end
