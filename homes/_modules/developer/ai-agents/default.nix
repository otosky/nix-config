{config, ...}: let
  nixConfigProject = "${config.home.homeDirectory}/personal/nix-config";
in {
  home.file = {
    ".claude/CLAUDE.md".source = ./instructions.md;
    ".codex/AGENTS.md".source = ./instructions.md;
    ".config/opencode/AGENTS.md".source = ./instructions.md;

    ".claude/skills/git-town/SKILL.md".source = ./skills/git-town/SKILL.md;
    ".agents/skills/git-town/SKILL.md".source = ./skills/git-town/SKILL.md;

    ".claude/agents/reviewer.md".source = ./agents/claude-reviewer.md;
    ".codex/agents/reviewer.toml".source = ./agents/codex-reviewer.toml;
    ".config/opencode/agents/reviewer.md".source = ./agents/opencode-reviewer.md;

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
