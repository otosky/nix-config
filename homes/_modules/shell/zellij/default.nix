{
  config,
  pkgs,
  ...
}: {
  programs.zellij = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    settings = {
      support_kitty_keyboard_protocol = true;
      show_startup_tips = false;
    };
  };
}
