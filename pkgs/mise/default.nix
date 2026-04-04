{
  lib,
  stdenv,
  fetchurl,
}: let
  version = "2026.4.3";
  sources = {
    x86_64-linux = {
      url = "https://github.com/jdx/mise/releases/download/v${version}/mise-v${version}-linux-x64-musl";
      hash = "sha256-f6CMYz2wQAtb8G/7XKNXBi2DwH2GoBdJtdlnI8Y+aHI=";
    };
    aarch64-linux = {
      url = "https://github.com/jdx/mise/releases/download/v${version}/mise-v${version}-linux-arm64-musl";
      hash = "sha256-bwt5L3QA9Im66Yp42nbTdmxivH0skYu3hVtUWoV70lw=";
    };
    aarch64-darwin = {
      url = "https://github.com/jdx/mise/releases/download/v${version}/mise-v${version}-macos-arm64";
      hash = "sha256-0LhpmrAEhT8Z+QP5fU7WZoX0CXUa4oOJ/wbzW2CsJUM=";
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
