{
  lib,
  stdenv,
  fetchzip,
  makeWrapper,
  autoPatchelfHook,
}: let
  platformMap = {
    "x86_64-linux" = {
      suffix = "linux-x64";
      hash = "sha256-MnjyrJuDrqFLfedzCQDD1j/9M0tKgpm1G+SUs3j0VmI=";
    };
    "aarch64-linux" = {
      suffix = "linux-arm64";
      hash = "sha256-XS7BdpSYQvnQbVelnZp4fHzqaZGe+kPIF34/7CU0QzY=";
    };
    "x86_64-darwin" = {
      suffix = "darwin-x64";
      hash = "sha256-SilpJELE0seiktX/RoM6YBGxWJ1dCISAU+PCNVpga4E=";
    };
    "aarch64-darwin" = {
      suffix = "darwin-arm64";
      hash = "sha256-T4Z/lj59J/mf1VzTyiW9WI2n5nfvy5dgBlr3et5hwkg=";
    };
  };
  platform = platformMap.${stdenv.hostPlatform.system};
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "opencode";
    version = "1.14.30";

    src = fetchzip {
      url = "https://registry.npmjs.org/opencode-${platform.suffix}/-/opencode-${platform.suffix}-${finalAttrs.version}.tgz";
      hash = platform.hash;
    };

    nativeBuildInputs =
      [makeWrapper]
      ++ lib.optionals stdenv.hostPlatform.isLinux [autoPatchelfHook];

    # glibc for the interpreter; cc.lib for libstdc++.so.6 which is dlopen'd at
    # runtime by bundled native modules (file watcher, state management).
    buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
      stdenv.cc.libc
      stdenv.cc.cc.lib
    ];

    dontBuild = true;
    # Self-contained Bun executable with embedded JS bundle; stripping corrupts it.
    dontStrip = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 bin/opencode $out/bin/opencode
      runHook postInstall
    '';

    postInstall = ''
      wrapProgram $out/bin/opencode \
        --set DISABLE_AUTOUPDATER 1 \
        --prefix LD_LIBRARY_PATH : "${stdenv.cc.cc.lib}/lib"
    '';

    meta = {
      description = "AI coding agent for the terminal";
      homepage = "https://opencode.ai";
      license = lib.licenses.mit;
      mainProgram = "opencode";
      platforms = builtins.attrNames platformMap;
    };
  })
