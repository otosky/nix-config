{pkgs, ...}: {
  fontProfiles = {
    enable = true;
    monospace = {
      family = "JetBrainsMono Nerd Font";
      package = pkgs.nerd-fonts.jetbrains-mono;
    };
    regular = {
      family = "JetBrainsMono";
      package = pkgs.jetbrains-mono;
    };
  };

  home.packages = with pkgs; [
    font-awesome
  ];
}
