{
  config,
  lib,
  pkgs,
  ...
}: {
  services.ollama = {
    enable = true;
    package = lib.mkDefault pkgs.ollama;
  };

  environment.systemPackages = [config.services.ollama.package];
}
