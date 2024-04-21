{
  pkgs,
  lib,
  config,
  ...
}: let
  ssh = "${pkgs.openssh}/bin/ssh";
in {
  programs.git = {
    enable = true;
    package = pkgs.gitAndTools.gitFull;
    userName = "Oliver Tosky";
    userEmail = "olivertosky@gmail.com";
    signing = {
      key = "005F0191AFEEAD6FF90F78DB71E926104222B60F";
      signByDefault = true;
    };
    extraConfig = {
      init.defaultBranch = "main";

      merge.conflictStyle = "zdiff3";
      commit.verbose = true;
      diff.algorithm = "histogram";
      log.date = "iso";
      column.ui = "auto";
      branch.sort = "committerdate";
      # Automatically track remote branch
      push.autoSetupRemote = true;
      # Reuse merge conflict fixes when rebasing
      rerere.enabled = true;
    };
    lfs.enable = true;
    ignores = [
      ".direnv"
      "result"
    ];
  };
}
