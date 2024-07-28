{
  config,
  pkgs,
  ...
}: {
  home = {
    packages = with pkgs; [
      coursier
      delta
      age
      fd
      gnumake
    ];
  };

  programs.opam.enable = true;
  programs.bat = {
    enable = true;
  };
}
