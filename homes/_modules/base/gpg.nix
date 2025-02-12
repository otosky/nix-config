{
  pkgs,
  config,
  lib,
  ...
}: {
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    sshKeys = [
      "414D4FC4828AAC81412AED6E9CC9DFD09CA07570"
    ];
    enableExtraSocket = true;
    pinentryPackage = pkgs.pinentry-gtk2;
  };

  programs = let
    fixGpg =
      /*
      bash
      */
      ''
        gpgconf --launch gpg-agent
      '';
    gpgKey = pkgs.fetchurl {
      url = "https://keybase.io/otosky/pgp_keys.asc";
      sha256 = "Fm4o9XSVuJgcdcGS7d9z2c2lEbe0W++5uj0Iz9g+VcY=";
    };
  in {
    # Start gpg-agent if it's not running or tunneled in
    # SSH does not start it automatically, so this is needed to avoid having to use a gpg command at startup
    # https://www.gnupg.org/faq/whats-new-in-2.1.html#autostart
    bash.profileExtra = fixGpg;
    fish.loginShellInit = fixGpg;
    zsh.loginExtra = fixGpg;

    gpg = {
      enable = true;
      settings = {
        trust-model = "tofu+pgp";
      };
      publicKeys = [
        {
          source = "${gpgKey}";
          trust = 5;
        }
      ];
    };
  };

  systemd.user.services = {
    # Link /run/user/$UID/gnupg to ~/.gnupg-sockets
    # So that SSH config does not have to know the UID
    link-gnupg-sockets = {
      Unit = {
        Description = "link gnupg sockets from /run to /home";
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.coreutils}/bin/ln -Tfs /run/user/%U/gnupg %h/.gnupg-sockets";
        ExecStop = "${pkgs.coreutils}/bin/rm $HOME/.gnupg-sockets";
        RemainAfterExit = true;
      };
      Install.WantedBy = ["default.target"];
    };
  };
}
