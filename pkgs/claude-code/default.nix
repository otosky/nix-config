{
  lib,
  stdenv,
  buildNpmPackage,
  fetchzip,
  bubblewrap,
  procps,
  socat,
}:
buildNpmPackage (finalAttrs: {
  pname = "claude-code";
  version = "2.1.91";

  src = fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${finalAttrs.version}.tgz";
    hash = "sha256-u7jdM6hTYN05ZLPz630Yj7gI0PeCSArg4O6ItQRAMy4=";
  };

  npmDepsHash = "sha256-0ppKP+XMgTzVVZtL7GDsOjgvSPUDrUa7SoG048RLaNg=";

  strictDeps = true;

  postPatch = ''
    cp ${./package-lock.json} package-lock.json

    substituteInPlace cli.js \
      --replace-warn '#!/bin/bash' '#!/usr/bin/env bash'
  '';

  dontNpmBuild = true;

  env.AUTHORIZED = "1";

  postInstall = ''
    wrapProgram $out/bin/claude \
      --set DISABLE_AUTOUPDATER 1 \
      --unset DEV \
      --prefix PATH : ${
      lib.makeBinPath (
        [
          procps
        ]
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
  };
})
