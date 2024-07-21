{
  pkgs,
  config,
  ...
}: let
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in {
  users.mutableUsers = false;
  users.users.olivertosky = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups =
      [
        "wheel"
        "video"
        "audio"
      ]
      ++ ifTheyExist [
        "network"
        "i2c"
        "docker"
        "podman"
        "git"
        "libvirtd"
      ];

    # TODO: add ssh public key
    # openssh.authorizedKeys.keys = [(builtins.readFile ../../../../home/olivertosky/ssh.pub)];
    hashedPasswordFile = config.sops.secrets.olivertosky-password.path;
    packages = [pkgs.home-manager];
  };

  sops.secrets.olivertosky-password = {
    sopsFile = ../../secrets.yaml;
    neededForUsers = true;
  };

  home-manager.users.olivertosky = import ../../../../homes/olivertosky/${config.networking.hostName}.nix;

  security.pam.services = {
    swaylock = {};
  };
}
