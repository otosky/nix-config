{
  config,
  pkgs,
  ...
}: {
  home = {
    packages = with pkgs; [
      reaper
      renoise
    ];
  };
}
