{
  config,
  pkgs,
  ...
}: {
  programs = {
    lazygit = {
      enable = true;
      settings = {
        customCommands = [
          {
            key = "<c-x>";
            context = "files";
            description = "Conventional commit";
            command = "sh -c 'git commit -m \"$1\${2:+($2)}$3: $4\"' _ {{.Form.Type | quote}} {{.Form.Scope | quote}} {{.Form.Breaking | quote}} {{.Form.Message | quote}}";
            prompts = [
              {
                type = "menu";
                title = "Commit type:";
                key = "Type";
                options = [
                  {
                    value = "feat";
                    name = "feat";
                    description = "A new feature";
                  }
                  {
                    value = "fix";
                    name = "fix";
                    description = "A bug fix";
                  }
                  {
                    value = "docs";
                    name = "docs";
                    description = "Documentation changes";
                  }
                  {
                    value = "style";
                    name = "style";
                    description = "Code style changes";
                  }
                  {
                    value = "refactor";
                    name = "refactor";
                    description = "Code refactoring";
                  }
                  {
                    value = "test";
                    name = "test";
                    description = "Test changes";
                  }
                  {
                    value = "chore";
                    name = "chore";
                    description = "Maintenance tasks";
                  }
                  {
                    value = "build";
                    name = "build";
                    description = "Build system changes";
                  }
                  {
                    value = "ci";
                    name = "ci";
                    description = "CI configuration changes";
                  }
                  {
                    value = "perf";
                    name = "perf";
                    description = "Performance improvements";
                  }
                  {
                    value = "revert";
                    name = "revert";
                    description = "Revert a commit";
                  }
                ];
              }
              {
                type = "input";
                title = "Commit message:";
                key = "Message";
              }
              {
                type = "input";
                title = "Scope (optional):";
                key = "Scope";
              }
              {
                type = "menu";
                title = "Breaking change?";
                key = "Breaking";
                options = [
                  {
                    value = "";
                    name = "No";
                  }
                  {
                    value = "!";
                    name = "Yes";
                  }
                ];
              }
            ];
          }
        ];
      };
    };
  };
}
