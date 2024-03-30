#! /usr/bin/fish

function up -d 'Jump up directory tree by N levels.'
  # no args; default to jumping up a single directory
  if test (count $argv) -ne 1
    cd ..
  else if test $argv[1] -lt 1
    echo 'up: expecting a numeric arg greater than 0' >&2 && return 1
  else
    cd (string repeat -n $argv[1] '../')
  end
end 
