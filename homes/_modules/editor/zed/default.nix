# https://wiki.nixos.org/wiki/Zed#Home_manager_support
{
  inputs,
  pkgs,
  ...
}: {
  programs.zed-editor = {
    enable = true;

    userSettings = {
      vim_mode = true;
      load_direnv = "shell_hook";
      show_whitespaces = "all";
    };
  };
}
