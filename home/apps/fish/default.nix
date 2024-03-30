{
  config,
  pkgs,
  ...
}: {
  config = {
    home = {
      file = {
        ".config/fish" = {
          recursive = true;
          source = ./fish;
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
      ];
    };
  };
}
