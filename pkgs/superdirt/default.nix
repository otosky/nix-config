{
  lib,
  stdenv,
  fetchFromGitHub,
}:
let
  superdirt-src = fetchFromGitHub {
    owner = "musikinformatik";
    repo = "SuperDirt";
    rev = "v1.7.4";
    hash = "sha256-9qU9CHYAXbN1IE3xXDqGipuroifVaSVXj3c/cDfwM80=";
  };
  dirt-samples-src = fetchFromGitHub {
    owner = "tidalcycles";
    repo = "Dirt-Samples";
    rev = "e6f801712fe7f4753ebedc04afa544e34c2f9501";
    hash = "sha256-OzVvy/L6jfEgGx3dMdhe/PkfMAWVV0HQ9wGy500++fw=";
  };
in
stdenv.mkDerivation {
  pname = "superdirt";
  version = "1.7.4";

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/SuperDirt $out/Dirt-Samples
    cp -r ${superdirt-src}/. $out/SuperDirt/
    cp -r ${dirt-samples-src}/. $out/Dirt-Samples/
  '';

  meta = with lib; {
    description = "SuperDirt audio engine and samples for TidalCycles";
    homepage = "https://github.com/musikinformatik/SuperDirt";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
  };
}
