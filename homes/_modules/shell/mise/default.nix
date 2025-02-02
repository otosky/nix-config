{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.modules.shell.mise;
  tomlFormat = pkgs.formats.toml {};
in {
  # TODO: Replace with official home manager module once available
  options.modules.shell.mise = {
    enable = lib.mkEnableOption "mise";
    package = lib.mkPackageOption pkgs "mise" {};
    settings = lib.mkOption {
      inherit (tomlFormat) type;
      default = {};
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      cfg.package
    ];

    xdg.configFile = {
      "mise/config.toml" = {
        source = tomlFormat.generate "settings" {
          settings = {
            experimental = true;
            python_venv_auto_create = true;
            idiomatic_version_file = false;
          };
        };
      };
    };

    programs = {
      bash.initExtra = ''
        eval "$(${lib.getExe cfg.package} activate bash)"
      '';

      fish.shellInit = lib.mkAfter ''
        ${lib.getExe cfg.package} hook-env | source
        ${lib.getExe cfg.package} activate fish | source
      '';
    };
  };
}
