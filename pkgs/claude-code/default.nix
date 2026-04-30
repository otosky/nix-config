{
  lib,
  stdenv,
  fetchzip,
  makeWrapper,
  autoPatchelfHook,
  bubblewrap,
  procps,
  socat,
}:
let
  platformMap = {
    "x86_64-linux" = {
      suffix = "linux-x64";
      hash = "sha256-vQoFGcLSRBI+k5yZ9LYTAmYSSojkKN4RJx8vvMl2JWw=";
    };
    "aarch64-linux" = {
      suffix = "linux-arm64";
      hash = "sha256-TuzEnQimu29ZXkYCDufBGbfXbahKU5QsCJeVh7QkMJo=";
    };
    "x86_64-darwin" = {
      suffix = "darwin-x64";
      hash = "sha256-aFBD4gdEzkeZTg/AOQMVhIdS8kzk7ur9ZNHR5J9mqoc=";
    };
    "aarch64-darwin" = {
      suffix = "darwin-arm64";
      hash = "sha256-aeIbXYRQHt1DhWyowxxHyXFIfCmP6Nq+xl9n8uOuP24=";
    };
  };
  platform = platformMap.${stdenv.hostPlatform.system};
in
stdenv.mkDerivation (finalAttrs: {
  pname = "claude-code";
  version = "2.1.123";

  src = fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code-${platform.suffix}/-/claude-code-${platform.suffix}-${finalAttrs.version}.tgz";
    hash = platform.hash;
  };

  nativeBuildInputs =
    [ makeWrapper ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ stdenv.cc.libc ];

  dontBuild = true;
  # The binary is a self-contained Bun executable with an embedded JS bundle;
  # stripping it corrupts that bundle.
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 claude $out/bin/claude
    runHook postInstall
  '';

  postInstall = ''
    wrapProgram $out/bin/claude \
      --set DISABLE_AUTOUPDATER 1 \
      --set DISABLE_INSTALLATION_CHECKS 1 \
      --unset DEV \
      --prefix PATH : ${
      lib.makeBinPath (
        [ procps ]
        ++ lib.optionals stdenv.hostPlatform.isLinux [
          bubblewrap
          socat
        ]
      )
    }
  '';

  meta = {
    description = "Agentic coding tool that lives in your terminal";
    homepage = "https://github.com/anthropics/claude-code";
    license = lib.licenses.unfree;
    mainProgram = "claude";
    platforms = builtins.attrNames platformMap;
  };
})
