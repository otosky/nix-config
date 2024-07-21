{config, ...}: {
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    dockerSocket.enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  # TODO impermanence
  # environment.persistence = {
  #   "/persist".directories = ["/var/lib/containers"];
  # };
}
