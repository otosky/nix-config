{pkgs, ...}: {
  home = {
    packages = with pkgs; [
      reaper
      renoise
      supercollider
      haskellPackages.tidal
    ];
  };

  xdg.dataFile = {
    "SuperCollider/Quarks/SuperDirt".source = "${pkgs.superdirt}/SuperDirt";
    "SuperCollider/Quarks/Dirt-Samples".source = "${pkgs.superdirt}/Dirt-Samples";
  };
}
