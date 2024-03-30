{
  config,
  inputs,
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
    neovim

    git
    delta
    age

    bat
    fzf
    fd
    ripgrep
    tmux
    lazygit
    zoxide
  ];

  imports = [
    ../../apps/neovim
    ../../apps/fish
  ];

  nixpkgs.overlays = [
    inputs.neovim-nightly-overlay.overlay
  ];

  programs.git = {
    enable = true;
    userName = "Oliver Tosky";
    userEmail = "olivertosky@gmail.com";
    extraConfig = let
      deltaCommand = "${pkgs.delta}/bin/delta";
    in {
      core = {
        pager = "${deltaCommand} --diff-so-fancy";
      };
      delta = {
        navigate = true;
        light = false;
        side-by-side = true;
      };
      merge = {
        conflictstyle = "diff3";
      };
      diff = {
        colorMoved = "default";
      };
      interactive = {
        diffFilter = "${deltaCommand} --color-only";
      };
      init = {
        defaultBranch = "main";
      };
    };
  };
}
