{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  typescript-go,
  ripgrep,
}:
buildNpmPackage (finalAttrs: {
  pname = "pi-coding-agent";
  # renovate: datasource=github-tags depName=earendil-works/pi versioning=semver extractVersion=^v(?<version>.*)$
  version = "0.78.0";

  src = fetchFromGitHub {
    owner = "earendil-works";
    repo = "pi";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Cw+W5w6yuL+cH+JfgCbEwiyeXloMb7yFd46TXJPZGTg=";
  };

  npmDepsHash = "sha256-vNXInQTvB8h8/8PA0WcQ69Ni+pABK7n9wMr3pY3aY4c=";
  npmDepsFetcherVersion = 2;

  npmWorkspace = "packages/coding-agent";
  npmRebuildFlags = ["--ignore-scripts"];

  nativeBuildInputs = [typescript-go];

  postPatch = ''
    substituteInPlace tsconfig.base.json \
      --replace-fail '"ES2022"' '"ES2024"'
  '';

  buildPhase = ''
    runHook preBuild
    tsgo -p packages/ai/tsconfig.build.json
    tsgo -p packages/tui/tsconfig.build.json
    tsgo -p packages/agent/tsconfig.build.json
    npm run build --workspace=packages/coding-agent
    runHook postBuild
  '';

  postInstall = ''
    local nm="$out/lib/node_modules/pi-monorepo/node_modules"
    for ws in @earendil-works/pi-ai:packages/ai \
              @earendil-works/pi-agent-core:packages/agent \
              @earendil-works/pi-tui:packages/tui; do
      IFS=: read -r pkg src <<< "$ws"
      rm "$nm/$pkg"
      cp -r "$src" "$nm/$pkg"
    done
    find "$nm" -type l -lname '*/packages/*' -delete
    find "$nm/.bin" -xtype l -delete
  '';

  postFixup = ''
    wrapProgram $out/bin/pi \
      --prefix PATH : ${lib.makeBinPath [ripgrep]}
  '';

  meta = {
    description = "Coding agent CLI with read, bash, edit, write tools and session management";
    homepage = "https://pi.dev/";
    changelog = "https://github.com/earendil-works/pi/blob/main/packages/coding-agent/CHANGELOG.md";
    license = lib.licenses.mit;
    mainProgram = "pi";
  };
})
