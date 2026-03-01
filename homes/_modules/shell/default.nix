{pkgs, lib, ...}: {
  imports = [
    ./fish
    ./mise
    ./zoxide
    ./tmux
    ./zellij
  ];

  home = {
    packages = with pkgs; [
      just
      eza
      fd
      jq
      yq
      btop
      dig
      parallel
      xh
    ] ++ lib.optionals pkgs.stdenv.isLinux [
      nvtopPackages.full
    ];
  };

  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      silent = true;
    };
  };
}
