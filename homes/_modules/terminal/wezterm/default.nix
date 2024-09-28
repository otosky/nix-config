{
  config,
  inputs,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    inputs.wezterm.packages.${pkgs.system}.default
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
