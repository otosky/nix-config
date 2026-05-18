{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.ai;
  ollamaCli = pkgs.runCommand "ollama-cli-${cfg.localLlm.package.version}" {} ''
    mkdir -p "$out/bin"
    ln -s "${cfg.localLlm.package}/bin/ollama" "$out/bin/ollama"
  '';
in {
  options.modules.ai.localLlm = {
    enable = lib.mkEnableOption "local LLM tooling";

    package = lib.mkPackageOption pkgs "ollama" {};
  };

  config = lib.mkIf cfg.localLlm.enable {
    home.packages = [ollamaCli];
  };
}
