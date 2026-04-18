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

  nativeBuildInputs = [pkg-config];
  buildInputs = [libsecret];

  dontNpmBuild = true;

  postInstall = ''
    # @agor/core is a private workspace package bundled under dist/core/.
    # Node.js won't resolve it from the package.json imports map (non-# prefix),
    # so create a real node_modules entry pointing at the bundled dist.
    mkdir -p $out/lib/node_modules/agor-live/node_modules/@agor
    ln -s ../../dist/core $out/lib/node_modules/agor-live/node_modules/@agor/core
  '';

  meta = {
    description = "Multiplayer canvas for orchestrating AI coding sessions";
    homepage = "https://github.com/preset-io/agor";
    license = lib.licenses.asl20;
    mainProgram = "agor";
  };
})
