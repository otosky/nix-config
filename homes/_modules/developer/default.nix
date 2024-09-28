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
      gnumake
    ];
  };

  programs = {
    opam.enable = true;
    bat.enable = true;
    gh.enable = true;
  };
}
