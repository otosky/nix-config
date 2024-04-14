{pkgs, ...}: {
  fontProfiles = {
    enable = true;
    monospace = {
      family = "JetBrains Mono Nerd Font";
      package = pkgs.nerdfonts.override {fonts = ["JetBrains Mono"];};
    };
    regular = {
      family = "JetBrains Mono";
      package = pkgs.jetbrains-mono;
    };
  };
}
