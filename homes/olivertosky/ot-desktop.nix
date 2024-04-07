{lib, ...}: {
  imports = [../_modules/base];
  # Disable impermanence
  home.persistence = lib.mkForce {};
}
