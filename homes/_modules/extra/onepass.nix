{
  config,
  pkgs,
  lib,
  ...
}: {
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    # todo: make name dynamic
    polkitPolicyOwners = ["olivertosky"];
  };
}
