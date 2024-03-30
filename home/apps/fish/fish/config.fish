# vim: set ft=fish:
set -gx fish_key_bindings fish_vi_key_bindings
set -gx fish_greeting
set -gx POETRY_VIRTUALENVS_IN_PROJECT true
set -gx DIRENV_LOG_FORMAT ''
set -gx HOMEBREW_NO_AUTO_UPDATE 1
set -gx MISE_ENV_FILE .env
set -gx devbox_no_prompt true
set -gx EDITOR nvim

# interactive things
status is-interactive || exit

fish_add_path $HOME/.local/bin
mise activate fish | source

fish_add_path $HOME/bin/
fish_add_path $HOME/.krew/bin
fish_add_path (dirname (mise which cargo))
fish_add_path $HOME/.local/share/coursier/bin
fish_add_path $HOME/.ghcup/bin
fish_add_path $HOME/.docker/bin # for macOS
if command -q opam
    eval $(opam env)
end
# if test -e $HOME/.nix-profile/etc/profile.d/nix.fish
#  source $HOME/.nix-profile/etc/profile.d/nix.fish
# end

#direnv hook fish | source
fish_ssh_agent

zoxide init fish | source
