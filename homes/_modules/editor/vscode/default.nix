{
  inputs,
  pkgs,
  ...
}: {
  programs.vscode = {
    enable = true;
    profiles.default = {
      extensions = let
        # https://github.com/nix-community/nix-vscode-extensions/issues/99#issuecomment-2703326753
        pkgs-ext = import inputs.nixpkgs {
          inherit (pkgs) system;
          config.allowUnfree = true;
          overlays = [inputs.nix-vscode-extensions.overlays.default];
        };
        marketplace = pkgs-ext.vscode-marketplace;
      in
        with marketplace; [
          vscodevim.vim
          ms-python.python
          ms-vscode-remote.remote-containers
          innoverio.vscode-dbt-power-user
        ];
      userSettings = {
        "python.testing.pytestArgs" = [
          "tests"
        ];
        "python.testing.unittestEnabled" = false;
        "python.testing.pytestEnabled" = true;
      };
    };
  };
}
