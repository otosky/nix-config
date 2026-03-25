{
  config,
  pkgs,
  ...
}: {
  home.file = {
    ".claude/skills/git-town/SKILL.md".source = ./skills/git-town/SKILL.md;
  };
}
