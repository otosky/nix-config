{
  lib,
  pkgs,
  ...
}: {
  # Linux-specific home-manager settings

  systemd.user.startServices = "sd-switch";

  home.persistence = {
    "/persist" = {
      directories = [
        "Documents"
        "Downloads"
        "Pictures"
        "Videos"
        ".local/bin"
        ".local/share/nix" # trusted settings and repl history
        ".ssh"
      ];
    };
  };
}
