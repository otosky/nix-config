{
  config,
  pkgs,
  ...
}: {
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    dockerSocket.enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  environment.systemPackages = with pkgs; [
    dive
    podman-tui
    podman-compose
    distrobox
  ];

  # TODO impermanence
  # environment.persistence = {
  #   "/persist".directories = ["/var/lib/containers"];
  # };
}
