{
  config,
  lib,
  pkgs,
  ...
}: let
  nixConfigProject = "${config.home.homeDirectory}/personal/nix-config";
  claudeStatusline = "${config.home.homeDirectory}/.local/bin/claude-statusline";
  localPiEmoteFork = "${config.home.homeDirectory}/oss/pi-emote";
  piEmotePackage = "git:github.com/otosky/pi-emote@main";
  previousPiEmotePackages = ["file:${localPiEmoteFork}"];

  skillTargets = {
    ".claude/skills" = {
      recursive = true;
      source = ./skills;
    };

    ".agents/skills" = {
      recursive = true;
      source = ./skills;
    };
  };
in {
  home.file =
    skillTargets
    // {
      ".claude/CLAUDE.md".source = ./instructions.md;
      ".codex/AGENTS.md".source = ./instructions.md;
      ".config/opencode/AGENTS.md".source = ./instructions.md;

      ".pi/agent/AGENTS.md".source = ./instructions.md;

      ".pi/agent/extensions" = {
        force = true;
        recursive = true;
        source = ./pi/extensions;
      };

      ".pi/agent/keybindings.json".source = ./pi/keybindings.json;

      ".local/bin/claude-statusline" = {
        executable = true;
        source = ./claude-statusline;
      };

      ".codex/config.toml" = {
        # Codex only reads a single config.toml. Keep the known mutable NUX key
        # while making durable defaults reproducible through Home Manager.
        force = true;
        text = ''
          model = "gpt-5.5"
          approval_policy = "on-request"
          sandbox_mode = "workspace-write"
          personality = "pragmatic"
          web_search = "cached"

          ${lib.optionalString pkgs.stdenv.isDarwin ''
            [features]
            fast_mode = false
            apps = false

            [plugins."superpowers@openai-curated"]
            enabled = true
          ''}
          [agents]
          max_threads = 6
          max_depth = 1

          [tui]
          status_line = ["model", "context-used", "context-remaining", "five-hour-limit", "weekly-limit"]

          [projects."${nixConfigProject}"]
          trust_level = "trusted"

          [tui.model_availability_nux]
          "gpt-5.5" = 1
        '';
      };

      ".config/opencode/opencode.json" = {
        text = builtins.toJSON {
          "$schema" = "https://opencode.ai/config.json";
          autoupdate = false;
          instructions = ["AGENTS.md"];
          permission = {
            skill = {
              "*" = "allow";
            };
          };
        };
      };
    };

  home.activation.configurePiPackages = lib.hm.dag.entryAfter ["writeBoundary"] ''
    package=${lib.escapeShellArg piEmotePackage}
    previous_packages=${lib.escapeShellArg (builtins.toJSON previousPiEmotePackages)}
    settings_path="$HOME/.pi/agent/settings.json"
    settings_dir="$(${pkgs.coreutils}/bin/dirname "$settings_path")"
    ${pkgs.coreutils}/bin/mkdir -p "$settings_dir"

    tmp="$(${pkgs.coreutils}/bin/mktemp "$settings_dir/settings.json.tmp.XXXXXX")"
    if [ -e "$settings_path" ]; then
      if ! ${pkgs.jq}/bin/jq -e 'type == "object"' "$settings_path" >/dev/null; then
        echo "warning: leaving $settings_path unchanged; expected a JSON object" >&2
        ${pkgs.coreutils}/bin/rm -f "$tmp"
        exit 0
      fi
      input="$settings_path"
    else
      input="$tmp.input"
      printf '{}\n' > "$input"
    fi

    ${pkgs.jq}/bin/jq \
      --arg package "$package" \
      --argjson previous_packages "$previous_packages" \
      '.packages = (if (.packages | type) == "array" then (.packages | map(select(. as $existing | ($previous_packages | index($existing) | not))) | if any(. == $package) then . else . + [$package] end) else [$package] end)' \
      "$input" > "$tmp"

    if [ "$input" != "$settings_path" ]; then
      ${pkgs.coreutils}/bin/rm -f "$input"
    fi

    if [ -e "$settings_path" ] && ${pkgs.coreutils}/bin/cmp -s "$settings_path" "$tmp"; then
      ${pkgs.coreutils}/bin/rm -f "$tmp"
    else
      ${pkgs.coreutils}/bin/mv "$tmp" "$settings_path"
    fi
  '';

  home.activation.configureClaudeStatusline = lib.hm.dag.entryAfter ["writeBoundary"] ''
    export CLAUDE_STATUSLINE_COMMAND=${lib.escapeShellArg claudeStatusline}
    settings_path="$HOME/.claude/settings.json"
    settings_dir="$(${pkgs.coreutils}/bin/dirname "$settings_path")"
    ${pkgs.coreutils}/bin/mkdir -p "$settings_dir"

    tmp="$(${pkgs.coreutils}/bin/mktemp "$settings_dir/settings.json.tmp.XXXXXX")"
    if [ -e "$settings_path" ]; then
      if ! ${pkgs.jq}/bin/jq -e 'type == "object"' "$settings_path" >/dev/null; then
        echo "warning: leaving $settings_path unchanged; expected a JSON object" >&2
        ${pkgs.coreutils}/bin/rm -f "$tmp"
        exit 0
      fi
      input="$settings_path"
    else
      input="$tmp.input"
      printf '{}\n' > "$input"
    fi

    ${pkgs.jq}/bin/jq \
      --arg command "$CLAUDE_STATUSLINE_COMMAND" \
      '.statusLine = {"type":"command","command":$command,"padding":0}' \
      "$input" > "$tmp"

    if [ "$input" != "$settings_path" ]; then
      ${pkgs.coreutils}/bin/rm -f "$input"
    fi

    if [ -e "$settings_path" ] && ${pkgs.coreutils}/bin/cmp -s "$settings_path" "$tmp"; then
      ${pkgs.coreutils}/bin/rm -f "$tmp"
    else
      ${pkgs.coreutils}/bin/mv "$tmp" "$settings_path"
    fi
  '';
}
