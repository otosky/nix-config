{
  config,
  pkgs,
  ...
}: {
  config = {
    home = {
      file = {
        ".config/fish/conf.d" = {
          recursive = true;
          source = ./conf.d;
        };
        ".config/fish/functions" = {
          recursive = true;
          source = ./functions;
        };
        ".config/fish/themes" = {
          recursive = true;
          source = ./themes;
        };
      };
      packages = with pkgs; [
        fzf
      ];
    };

    programs.fish = {
      enable = true;

      plugins = [
        {
          name = "fzf";
          src = pkgs.fishPlugins.fzf-fish.src;
        }
        {
          name = "tide";
          src = pkgs.fishPlugins.tide.src;
          # tide configure --auto --style=Lean --prompt_colors='True color' --show_time='24-hour format' --lean_prompt_height='Two lines' --prompt_connection=Disconnected --prompt_spacing=Sparse --icons='Few icons' --transient=Yes
        }
        # {
        #   name = "pure";
        #   src = pkgs.fishPlugins.pure.src;
        # }
      ];

      shellInit = ''
        set -gx fish_key_bindings fish_vi_key_bindings
        set -gx fish_greeting
        set -gx POETRY_VIRTUALENVS_IN_PROJECT true
        set -gx DIRENV_LOG_FORMAT ""
        set -gx HOMEBREW_NO_AUTO_UPDATE 1
        set -gx MISE_ENV_FILE .env
        set -gx devbox_no_prompt true
        set -gx EDITOR nvim
        #tide configure --auto --style=Lean --prompt_colors='True color' --show_time='24-hour format' --lean_prompt_height='Two lines' --prompt_connection=Disconnected --prompt_spacing=Sparse --icons='Few icons' --transient=Yes
      '';

      interactiveShellInit = ''
        fish_add_path $HOME/.local/bin
        #mise activate fish | source

        fish_add_path $HOME/bin/
        fish_add_path $HOME/.krew/bin
        # fish_add_path (dirname (mise which cargo))
        fish_add_path $HOME/.local/share/coursier/bin
        fish_add_path $HOME/.ghcup/bin
        fish_add_path $HOME/.docker/bin # for macOS
        if command -q opam
            eval $(opam env)
        end

        fish_ssh_agent

        # zoxide init fish | source
      '';
    };
  };
}
