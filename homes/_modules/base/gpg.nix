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
    pinentry.package = pkgs.pinentry-gtk2;
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
      sha256 = "sha256-1yzZEusziS3CA8V4Qgtpj2KzLvEO6ra2hiPJEb9/YNU=";
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

  systemd.user.timers.refresh-gpg-keybase-key = {
    Unit.Description = "Refresh GPG public key metadata from Keybase weekly";
    Timer = {
      OnCalendar = "weekly";
      Persistent = true;
    };
    Install.WantedBy = ["timers.target"];
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

    refresh-gpg-keybase-key = {
      Unit.Description = "Refresh GPG public key metadata from Keybase";
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.gnupg}/bin/gpg --fetch-keys https://keybase.io/otosky/pgp_keys.asc";
      };
    };
  };
}
