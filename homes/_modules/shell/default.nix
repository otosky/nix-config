{pkgs, ...}: {
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
      nvtopPackages.full
      dig
      parallel
      xh
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
