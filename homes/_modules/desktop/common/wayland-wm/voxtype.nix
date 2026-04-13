{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.modules.voxtype;
  engineConfig =
    if cfg.engine == "parakeet"
    then ''
      [parakeet]
      model = "${cfg.model}"
    ''
    else ''
      [whisper]
      model = "${cfg.model}"
      language = "en"
      translate = false
      on_demand_loading = false
    '';
in {
  options.modules.voxtype = {
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.voxtype;
      description = "The voxtype package to use.";
    };
    engine = lib.mkOption {
      type = lib.types.enum ["whisper" "parakeet"];
      default = "whisper";
      description = "The transcription engine to use.";
    };
    model = lib.mkOption {
      type = lib.types.str;
      default = "base.en";
      description = "The model name to use for the selected engine.";
    };
  };

  config = {
    home.packages = [cfg.package];

    wayland.windowManager.hyprland.settings = {
      exec-once = ["${cfg.package}/bin/voxtype daemon"];

      bind = [
        ", F9, exec, voxtype record start"
      ];

      bindr = [
        ", F9, exec, voxtype record stop"
      ];
    };

    xdg.configFile."voxtype/config.toml".text = ''
      ${lib.optionalString (cfg.engine != "whisper") ''engine = "${cfg.engine}"''}
      state_file = "auto"

      [hotkey]
      enabled = false
      key = "F9"
      modifiers = []

      [audio]
      device = "default"
      sample_rate = 16000
      max_duration_secs = 60

      ${engineConfig}
      [output]
      mode = "type"
      fallback_to_clipboard = true
      type_delay_ms = 0
      pre_type_delay_ms = 0

      [output.notification]
      on_recording_start = false
      on_recording_stop = false
      on_transcription = true

      [status]
      icon_theme = "emoji"
    '';
  };
}
