{pkgs, ...}: let
  version = "2.6.6";
  vcv-rack-src = pkgs.fetchurl {
    url = "https://vcvrack.com/downloads/RackFree-${version}-lin-x64.zip";
    hash = "sha256-aazwyY1H2zgSkaEV1gnc+7mYh7172GQfBInaBj+w/G4=";
  };
  vcv-rack-extracted =
    pkgs.runCommand "vcv-rack-${version}" {
      nativeBuildInputs = [pkgs.unzip];
    } ''
      unzip ${vcv-rack-src} -d $out
    '';
  vcv-rack = pkgs.buildFHSEnv {
    name = "vcv-rack";
    targetPkgs = pkgs:
      with pkgs; [
        mesa
        libGL
        libx11
        libxext
        libxcursor
        libxrandr
        libxinerama
        libxi
        alsa-lib
        libpulseaudio
      ];
    runScript = pkgs.writeShellScript "run-vcv-rack" ''
      cd ${vcv-rack-extracted}/Rack2Free
      exec ./Rack "$@"
    '';
  };
in {
  home.packages = [vcv-rack];

  xdg.desktopEntries.vcv-rack = {
    name = "VCV Rack";
    exec = "vcv-rack";
    terminal = false;
    type = "Application";
    categories = ["Audio" "Music"];
  };
}
