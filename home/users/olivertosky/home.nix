{
  config,
  lib,
  pkgs,
  ...
}: {
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  home.stateVersion = "22.11";
  home.username = "olivertosky";
  home.homeDirectory = "/home/olivertosky";

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  home.packages = with pkgs; [
    nixpkgs-fmt
  ];

  imports = [
    ../../apps/neovim
  ];
}
