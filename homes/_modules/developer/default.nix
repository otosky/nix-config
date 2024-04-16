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
    ];
  };

  programs.opam.enable = true;
  programs.bat = {
    enable = true;
  };
}
