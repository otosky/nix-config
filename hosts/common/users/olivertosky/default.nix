{
  pkgs,
  config,
  ...
}: let
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in {
  users.mutableUsers = true;
  users.users.olivertosky = {
    password = "example";
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

    # openssh.authorizedKeys.keys = [(builtins.readFile ../../../../home/misterio/ssh.pub)];
    # hashedPasswordFile = config.sops.secrets.misterio-password.path;
    packages = [pkgs.home-manager];
  };

  # sops.secrets.misterio-password = {
  #   sopsFile = ../../secrets.yaml;
  #   neededForUsers = true;
  # };

  home-manager.users.olivertosky = import ../../../../homes/olivertosky/${config.networking.hostName}.nix;

  security.pam.services = {
    swaylock = {};
  };
}
