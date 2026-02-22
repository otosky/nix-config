{
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    wezterm
  ];

  xdg.configFile = {
    "wezterm/wezterm.lua" = {
      source = ./wezterm.lua;
    };
  };

  # config = {
  #   programs.wezterm = {
  #     enable = true;
  #     package = pkgs.wezterm;
  #     extraConfig = builtins.readFile ./wezterm.lua;
  #   };
  # };
}
