{config, ...}: let
  inherit (config.networking) hostName;
in {
  programs._1password-gui.enable = true;
  programs._1password.enable = true;
  programs._1password-gui.polkitPolicyOwners = [hostName];
}
