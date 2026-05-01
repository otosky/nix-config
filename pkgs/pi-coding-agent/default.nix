{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  typescript-go,
  ripgrep,
}:
buildNpmPackage (finalAttrs: {
  pname = "pi-coding-agent";
  version = "0.70.6";

  src = fetchFromGitHub {
    owner = "badlogic";
    repo = "pi-mono";
    tag = "v${finalAttrs.version}";
    hash = "sha256-XZUnKk+B9kWn51kRfMkfInYCz+5hVuWQBvgOm9PO9bo=";
  };

  npmDepsHash = "sha256-pEVIqp9rbuHFE6eqSmADmIXWAPey1VbD7qmOJwksz1o=";

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
    for ws in @mariozechner/pi-ai:packages/ai \
              @mariozechner/pi-agent-core:packages/agent \
              @mariozechner/pi-tui:packages/tui; do
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
    homepage = "https://shittycodingagent.ai/";
    changelog = "https://github.com/badlogic/pi-mono/blob/main/packages/coding-agent/CHANGELOG.md";
    license = lib.licenses.mit;
    mainProgram = "pi";
  };
})
