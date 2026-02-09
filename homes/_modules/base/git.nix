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
    package = pkgs.gitFull;
    signing = {
      key = "656968EFE265ED715AF5F2BF1CDC6147DE47244F";
      signByDefault = true;
    };
    settings = {
      user.name = "Oliver Tosky";
      user.email = "olivertosky@gmail.com";
      user.useconfigonly = true;

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

      git-town.github-connector = "gh";
      git-town.main-branch = "main";
    };
    lfs.enable = true;
    ignores = [
      ".direnv"
      "result"
    ];
  };
}
