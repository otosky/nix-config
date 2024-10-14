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
    ];
  };
}
