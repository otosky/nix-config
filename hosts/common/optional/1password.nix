{
  config,
  lib,
  ...
}: let
  normalUsers = lib.attrNames (lib.filterAttrs (_: user: user.isNormalUser or false) config.users.users);
in {
  programs._1password-gui.enable = true;
  programs._1password.enable = true;
  programs._1password-gui.polkitPolicyOwners = normalUsers;
}
