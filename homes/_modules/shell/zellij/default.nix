{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.zellij = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
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
