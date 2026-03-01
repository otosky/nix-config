{
  inputs,
  lib,
  pkgs,
  config,
  outputs,
  ...
}: {
  imports =
    [
      ./gpg.nix
      ./git.nix
      ./ssh.nix
      ../editor
      ../shell
    ]
    ++ (builtins.attrValues outputs.homeModules);

  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "ca-derivations"
      ];
      warn-dirty = false;
    };
  };

  programs = {
    home-manager.enable = true;
    git.enable = true;
  };

  home = {
    username = lib.mkDefault "olivertosky";
    homeDirectory = lib.mkDefault (
      if pkgs.stdenv.isDarwin
      then "/Users/${config.home.username}"
      else "/home/${config.home.username}"
    );
    stateVersion = lib.mkDefault "23.11";
    sessionPath = ["$HOME/.local/bin"];
    sessionVariables = {
      FLAKE = "$HOME/Documents/NixConfig";
    };
  };
}
