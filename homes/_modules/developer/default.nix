{
  config,
  pkgs,
  ...
}: {
  config = {
    home = {
      packages = with pkgs; [
        coursier
        opam
        bat
        delta
        age
        fd
      ];
    };
  };
}
