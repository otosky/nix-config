{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./k9s.nix
  ];

  config = {
    home = {
      packages = with pkgs; [
        fluxcd
      ];
    };
  };
}
