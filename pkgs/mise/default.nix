{
  lib,
  stdenv,
  fetchurl,
}: let
  version = "2026.4.17";
  sources = {
    x86_64-linux = {
      url = "https://github.com/jdx/mise/releases/download/v${version}/mise-v${version}-linux-x64-musl";
      hash = "sha256-eKTECRmraSK0aBEhh1MD9hKWc6Dapd4RNsUwf6blCjg=";
    };
    aarch64-linux = {
      url = "https://github.com/jdx/mise/releases/download/v${version}/mise-v${version}-linux-arm64-musl";
      hash = "sha256-W85ErADa2VwJw7gnIklJsN8huJm1bqMNtibKrgzOm18=";
    };
    aarch64-darwin = {
      url = "https://github.com/jdx/mise/releases/download/v${version}/mise-v${version}-macos-arm64";
      hash = "sha256-kbsP5tdNmDhpeXpzV91N9Pci5FXhZ/DVHOumvJ39u5s=";
    };
  };
  src = sources.${stdenv.hostPlatform.system} or (throw "Unsupported platform: ${stdenv.hostPlatform.system}");
in
  stdenv.mkDerivation {
    pname = "mise";
    inherit version;

    src = fetchurl {
      inherit (src) url hash;
    };

    dontUnpack = true;

    installPhase = ''
      install -Dm755 $src $out/bin/mise
    '';

    meta = with lib; {
      description = "Dev tools, env vars, task runner";
      homepage = "https://mise.jdx.dev";
      license = licenses.mit;
      mainProgram = "mise";
      platforms = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
    };
  }
