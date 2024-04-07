{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  nixGL = import ../../nixGL.nix {inherit pkgs config;};
in {
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  home.stateVersion = "22.11";
  home.username = "olivertosky";
  home.homeDirectory = "/home/olivertosky";

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  home.packages = with pkgs; [
    nixpkgs-fmt
    neovim

    git
    delta
    age

    bat
    fzf
    fd
    ripgrep
    tmux
    lazygit
    zoxide
  ];

  imports = [
    ./options.nix
    ../../apps/neovim
    ../../apps/fish
  ];

  nixpkgs.overlays = [
    inputs.neovim-nightly-overlay.overlay
  ];

  programs.git = {
    enable = true;
    userName = "Oliver Tosky";
    userEmail = "olivertosky@gmail.com";
    extraConfig = let
      deltaCommand = "${pkgs.delta}/bin/delta";
    in {
      core = {
        pager = "${deltaCommand} --diff-so-fancy";
      };
      delta = {
        navigate = true;
        light = false;
        side-by-side = true;
      };
      merge = {
        conflictstyle = "diff3";
      };
      diff = {
        colorMoved = "default";
      };
      interactive = {
        diffFilter = "${deltaCommand} --color-only";
      };
      init = {
        defaultBranch = "main";
      };
    };
  };

  programs.vim = {
    enable = true;
    settings = {
      number = true;
      relativenumber = true;
      expandtab = true;
      tabstop = 2;
      shiftwidth = 2;
    };
    extraConfig = ''
      " settings
      syntax on
      set autoindent
      set smarttab
      set backspace=indent,eol,start
      set hlsearch
      set incsearch
      set colorcolumn=100
      set nowrap
      set noswapfile
      set laststatus=2
      set scrolloff=8

      " remaps
      let mapleader = " "
      inoremap <C-L> <Esc>
      nnoremap <C-n> :nohl <CR>
      nnoremap Y y$
      nnoremap L $
      nnoremap H ^
      nnoremap dH d^
      tnoremap <Esc> <C-\><C-n>

      " move text
      vnoremap J :m '>+1<CR>gv=gv
      vnoremap K :m '<-2<CR>gv=gv
      inoremap <C-j> <esc>:m .+1<CR>==
      inoremap <C-k> <esc>:m .-2<CR>==
      nnoremap <leader>k :m .-2<CR>==
      nnoremap <leader>j :m .+1<CR>==

      xnoremap <leader>p "_dP
    '';
  };

  programs.wezterm = {
    enable = true;
    package = nixGL pkgs.wezterm;
    extraConfig = builtins.readFile ../../apps/wezterm/wezterm.lua;
  };

  programs.wofi = {
    enable = true;
  };
}
