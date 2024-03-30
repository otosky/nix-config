#! /usr/bin/fish

function ghgo -d "Open Github repo page in browser."
  gh repo view --web $argv
end
