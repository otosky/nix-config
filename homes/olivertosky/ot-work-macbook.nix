{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../_modules/base
    ../_modules/terminal
    ../_modules/developer
  ];

  home.username = "oliver.tosky";

  programs.git = {
    settings.user.email = lib.mkForce "oliver.tosky@stubhub.com";
    signing.key = lib.mkForce "200F44D11B87E2B868AAEAD2EF3F73D616D190A0";
  };

  services.gpg-agent.pinentry.package = lib.mkForce pkgs.pinentry_mac;

  modules = {
    shell = {
      mise = {
        enable = true;
        package = pkgs.mise;
      };
    };
  };
}
