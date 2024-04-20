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
    extraConfig = {
      init.defaultBranch = "main";

      gpg = {
        format = "ssh";
        ssh.defaultKeyCommand = "sh -c 'echo key::$(ssh-add -L | head -1)'";
      };
      commit.gpgsign = true;

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
