{
  lib,
  buildNpmPackage,
  fetchzip,
  pkg-config,
  libsecret,
}:
buildNpmPackage (finalAttrs: {
  pname = "agor";
  version = "0.16.5";

  src = fetchzip {
    url = "https://registry.npmjs.org/agor-live/-/agor-live-${finalAttrs.version}.tgz";
    hash = "sha256-8hHnJE4/mHkMZZjeNDq6geVNXeBhlv/LK61/XvY4U+k=";
  };

  npmDepsHash = "sha256-037ocYtMRqACw5qoAIfpjBGqTD8V2yL9+VQBg1NGiKI=";

  postPatch = ''
    cp ${./package-lock.json} package-lock.json

    # Replace workspace:* dependency with published version
    substituteInPlace package.json \
      --replace-warn '"@agor-live/client": "workspace:*"' '"@agor-live/client": "^${finalAttrs.version}"'
  '';

  nativeBuildInputs = [pkg-config libsecret];
  buildInputs = [libsecret];

  strictDeps = true;
  dontNpmBuild = true;

  postInstall = ''
    # @agor/core is a private workspace package bundled under dist/core/.
    # The package.json "imports" field maps "@agor/core" -> "./dist/core/index.js",
    # but Node.js only honors "#"-prefixed keys in "imports" — "@"-prefixed keys are
    # silently ignored. A node_modules symlink is the only way to make it resolvable.
    mkdir -p $out/lib/node_modules/agor-live/node_modules/@agor
    ln -s ../../dist/core $out/lib/node_modules/agor-live/node_modules/@agor/core
  '';

  meta = {
    description = "Multiplayer canvas for orchestrating AI coding sessions";
    homepage = "https://github.com/preset-io/agor";
    license = lib.licenses.bsl11;
    mainProgram = "agor";
  };
})
