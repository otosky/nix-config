{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.zellij = {
    enable = true;
    enableBashIntegration = false;
    enableZshIntegration = false;
    enableFishIntegration = false;
    settings =
      {
        support_kitty_keyboard_protocol = true;
        show_startup_tips = false;
      }
      // lib.optionalAttrs pkgs.stdenv.isLinux {
        copy_command = "${pkgs.wl-clipboard}/bin/wl-copy";
      }
      // lib.optionalAttrs pkgs.stdenv.isDarwin {
        copy_command = "pbcopy";
      };
  };
}
