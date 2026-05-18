{
  config,
  lib,
  pkgs,
  ...
}: let
  nixConfigProject = "${config.home.homeDirectory}/personal/nix-config";
  claudeStatusline = "${config.home.homeDirectory}/.local/bin/claude-statusline";
  piEmotePackage = "git:github.com/cgxeiji/pi-emote@f6f66f332619a79190e78bda0a538da5692a62da";
  previousPiEmotePackages = [];
  ollamaPiProvider = {
    baseUrl = "http://localhost:11434/v1";
    api = "openai-completions";
    apiKey = "ollama";
    compat = {
      supportsDeveloperRole = false;
      supportsReasoningEffort = false;
    };
    models = [
      {
        id = "qwen3.5:9b";
        name = "Qwen 3.5 9B Local";
        contextWindow = 32768;
        maxTokens = 8192;
      }
      {
        id = "qwen3.5:27b";
        name = "Qwen 3.5 27B Local";
        contextWindow = 32768;
        maxTokens = 8192;
      }
      {
        id = "qwen3.6:27b";
        name = "Qwen 3.6 27B Local";
        contextWindow = 32768;
        maxTokens = 8192;
      }
      {
        id = "gemma4:e4b";
        name = "Gemma 4 E4B Local";
        contextWindow = 32768;
        maxTokens = 8192;
      }
      {
        id = "llama3.1:8b";
        name = "Llama 3.1 8B Local";
        contextWindow = 32768;
        maxTokens = 8192;
      }
    ];
  };

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

  home.activation.configureCodex = lib.hm.dag.entryAfter ["writeBoundary"] ''
    config_path="$HOME/.codex/config.toml"
    config_dir="$(${pkgs.coreutils}/bin/dirname "$config_path")"
    ${pkgs.coreutils}/bin/mkdir -p "$config_dir"

    if [ -L "$config_path" ]; then
      tmp="$(${pkgs.coreutils}/bin/mktemp "$config_dir/config.toml.tmp.XXXXXX")"
      ${pkgs.coreutils}/bin/cp "$config_path" "$tmp"
      ${pkgs.coreutils}/bin/mv "$tmp" "$config_path"
    elif [ ! -e "$config_path" ]; then
      ${pkgs.coreutils}/bin/touch "$config_path"
    fi

    # Keep root keys before TOML tables, otherwise newly-added root keys would
    # parse as members of the last table.
    if ! ${pkgs.yq-go}/bin/yq -i -p toml -o toml ${lib.escapeShellArg ''
      .model = "gpt-5.5" |
      .approval_policy = "on-request" |
      .sandbox_mode = "workspace-write" |
      .personality = "pragmatic" |
      .web_search = "cached" |
      ${lib.optionalString pkgs.stdenv.isDarwin ''
        .features.fast_mode = false |
        .features.apps = false |
        .plugins."superpowers@openai-curated".enabled = true |
      ''}
      .agents.max_threads = 6 |
      .agents.max_depth = 1 |
      .tui.status_line = ["model", "context-used", "context-remaining", "five-hour-limit", "weekly-limit"] |
      .projects."${nixConfigProject}".trust_level = "trusted" |
      .tui.model_availability_nux."gpt-5.5" = 1 |
      (with_entries(select(.value | tag != "!!map")) * with_entries(select(.value | tag == "!!map")))
    ''} "$config_path"; then
      echo "warning: leaving $config_path unchanged; expected valid TOML" >&2
    fi
  '';

  home.activation.configurePiModels = lib.hm.dag.entryAfter ["writeBoundary"] ''
    provider=${lib.escapeShellArg (builtins.toJSON ollamaPiProvider)}
    models_path="$HOME/.pi/agent/models.json"
    models_dir="$(${pkgs.coreutils}/bin/dirname "$models_path")"
    ${pkgs.coreutils}/bin/mkdir -p "$models_dir"

    tmp="$(${pkgs.coreutils}/bin/mktemp "$models_dir/models.json.tmp.XXXXXX")"
    if [ -e "$models_path" ]; then
      if ! ${pkgs.jq}/bin/jq -e 'type == "object"' "$models_path" >/dev/null; then
        echo "warning: leaving $models_path unchanged; expected a JSON object" >&2
        ${pkgs.coreutils}/bin/rm -f "$tmp"
        exit 0
      fi
      input="$models_path"
    else
      input="$tmp.input"
      printf '{}\n' > "$input"
    fi

    ${pkgs.jq}/bin/jq \
      --argjson provider "$provider" \
      '.providers = ((.providers // {}) + {ollama: $provider})' \
      "$input" > "$tmp"

    if [ "$input" != "$models_path" ]; then
      ${pkgs.coreutils}/bin/rm -f "$input"
    fi

    if [ -e "$models_path" ] && ${pkgs.coreutils}/bin/cmp -s "$models_path" "$tmp"; then
      ${pkgs.coreutils}/bin/rm -f "$tmp"
    else
      ${pkgs.coreutils}/bin/mv "$tmp" "$models_path"
    fi
  '';

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
