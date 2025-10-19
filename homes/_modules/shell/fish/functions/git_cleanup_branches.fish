function git_cleanup_branches
    set branches (git branch -vv | grep ': gone]' | awk '{print $1}')
    and set branch (printf '%s\n' $branches | fzf --multi --prompt="Filter branches: " --header="Branches with deleted upstreams (Tab to select multiple)")
    and git branch -D (printf '%s\n' $branch | sed "s/.* //" | sed "s#remotes/[^/]*/##")
end
