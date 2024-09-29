{pkgs, ...}: {
  programs.neovim = {
    enable = true;
  };

  home = {
    file = {
      ".config/nvim" = {
        recursive = true;
        source = ./nvim;
      };
    };
    packages = with pkgs; [
      # lazyvim deps
      gcc
      # telescope dependency
      ripgrep
      # build language servers
      nodejs
      python3
      cargo
      lua51Packages.jsregexp
      unzip
      # for git ui
      lazygit

      # lsps
      nil
      lua-language-server
      pyright
      gopls

      # formatters
      alejandra
      shfmt
      stylua
    ];
  };
}
