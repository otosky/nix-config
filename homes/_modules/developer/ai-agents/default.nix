{config, ...}: let
  nixConfigProject = "${config.home.homeDirectory}/personal/nix-config";

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
}
