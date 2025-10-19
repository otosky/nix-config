#! /usr/bin/fish

abbr vi nvim
abbr icat "kitty +kitten icat"
abbr wgup "wg-quick up wg0"
abbr wgdown "wg-quick down wg0"
abbr lsa "ls -a"

abbr cdr z

abbr ga 'git add'
abbr gaa 'git add --all'
abbr gba 'git branch -a'
abbr gbd 'git branch -d'
abbr gbD 'git branch -D'
abbr gbx git_cleanup_branches
abbr gbl 'git blame -b -w'
abbr gc 'git commit -v'
abbr gco 'git checkout'
abbr gd 'git diff'
abbr gfo 'git fetch origin'
abbr gfa 'git fetch --all --prune'
abbr gpsup 'git push --set-upstream origin $(git_current_branch)'
abbr gl 'git pull'
abbr gm 'git merge'
abbr gmom 'git merge origin/$(git_main_branch)'
abbr gp 'git push'
abbr grhh 'git reset --hard'
abbr groh 'git reset origin/$(git_current_branch) --hard'
abbr gst 'git status'

abbr gwta 'git worktree add'
abbr gwtl 'git worktree list'
abbr gwtr 'git worktree remove'

abbr k kubectl
abbr kn 'kubectl ns'
abbr kgn 'kubectl get nodes'
abbr kgp 'kubectl get pods'
abbr kl 'kubectl logs'
abbr ku k9s

# think "rc-edit":
abbr rce 'chezmoi edit'
# think "rc-yes":
abbr rcy 'chezmoi apply'
abbr rccd 'cd ~/.local/share/chezmoi' # I don't like how chezmoi cd spawns a subshell
abbr rca 'chezmoi add'

abbr tffmt 'terraform fmt'
abbr tffmta 'terraform fmt -recursive'
abbr tfp 'terraform plan'
abbr tfv 'terraform validate'

abbr fluxrs 'flux reconcile source git home-ops-kubernetes'
abbr fluxrk 'flux reconcile ks'
abbr fluxpause 'flux suspend'
abbr fluxplay 'flux resume'

abbr tm tmux
abbr tma 'tmux attach-session'
abbr tmat 'tmux attach-session -t'
abbr tml 'tmux list-sessions'
abbr tmn 'tmux new-session'
abbr tmns 'tmux new-session -s'

abbr mux tmuxinator
abbr muxn 'tmuxinator new'

abbr t 'todo.sh'

abbr lg lazygit
