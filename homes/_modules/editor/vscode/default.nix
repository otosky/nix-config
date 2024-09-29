{
  inputs,
  pkgs,
  ...
}: {
  programs.vscode = {
    enable = true;
    extensions = let
      inherit (inputs.nix-vscode-extensions.extensions.${pkgs.system}) vscode-marketplace;
    in
      with vscode-marketplace; [
        vscodevim.vim
        ms-python.python
        ms-vscode-remote.remote-containers
        innoverio.vscode-dbt-power-user
      ];
    settings = ''
    {
    "python.testing.pytestArgs": [
        "tests"
    ],
    "python.testing.unittestEnabled": false,
    "python.testing.pytestEnabled": true
    }
    ''
  };
}
