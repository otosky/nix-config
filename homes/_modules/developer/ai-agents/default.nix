{
  config,
  lib,
  pkgs,
  ...
}: let
  nixConfigProject = "${config.home.homeDirectory}/personal/nix-config";
  claudeStatusline = "${config.home.homeDirectory}/.local/bin/claude-statusline";
  claudeStatuslineScript = pkgs.writeShellScript "claude-statusline" ''
    ${pkgs.jq}/bin/jq -r '
      def number_or_null:
        if type == "number" then .
        elif . == null then null
        else try tonumber catch null
        end;

      def percent:
        (. | number_or_null) as $number
        | if $number == null then "?%"
          elif $number > 0 and $number < 0.1 then "<0.1%"
          elif (($number | floor) == $number) then "\($number | floor)%"
          else "\((($number * 10) | round) / 10)%"
          end;

      def token_text:
        (. | number_or_null) as $number
        | if $number == null then "?"
          else ($number | floor | tostring)
          end;

      def context:
        (.context_window // {}) as $window
        | (($window.total_input_tokens | number_or_null) // 0) as $input
        | (($window.total_output_tokens | number_or_null) // 0) as $output
        | ($input + $output) as $used_tokens
        | ($window.context_window_size | number_or_null) as $window_size
        | (
            if ($window_size != null and $window_size != 0)
            then ($used_tokens / $window_size * 100)
            else null
            end
          ) as $used_percent
        | "🧠 ctx: \($used_percent | percent) used \($used_tokens | token_text)/\($window_size | token_text)";

      def compact_duration:
        (. | floor) as $seconds
        | if $seconds <= 0 then "now"
          else
            (($seconds / 86400) | floor) as $days
            | ((($seconds % 86400) / 3600) | floor) as $hours
            | ((($seconds % 3600) / 60) | floor) as $minutes
            | if $days > 0 then
                "\($days)d" + if $hours > 0 then "\($hours)h" else "" end
              elif $hours > 0 then
                "\($hours)h" + if $minutes > 0 then "\($minutes)m" else "" end
              else
                "\($minutes)m"
              end
          end;

      def reset_text:
        (. | number_or_null) as $epoch
        | if $epoch == null then "resets ?"
          else "resets in \(($epoch - now) | compact_duration)"
          end;

      def rate_limit($key; $label):
        (.rate_limits[$key] // {}) as $window
        | ($window.used_percentage | number_or_null) as $used
        | ($window.resets_at | number_or_null) as $reset_epoch
        | if $used == null and $reset_epoch == null then empty
          elif $used == null then "\($label): \($reset_epoch | reset_text)"
          else "\($label): \($used | percent) used; \($reset_epoch | reset_text)"
          end;

      [
        "🤖 \(.model.display_name // .model.name // .model.id // "Claude")",
        context,
        rate_limit("five_hour"; "🕔 5h"),
        rate_limit("seven_day"; "📅 7d")
      ] | join(" · ")
    '
  '';

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

      ".local/bin/claude-statusline".source = claudeStatuslineScript;

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
