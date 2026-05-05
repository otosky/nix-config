# This file defines overlays
{inputs, ...}: {
  codex = inputs.codex-cli-nix.overlays.default;

  # For every flake input, aliases 'pkgs.inputs.${flake}' to
  # 'inputs.${flake}.packages.${pkgs.stdenv.hostPlatform.system}' or
  # 'inputs.${flake}.legacyPackages.${pkgs.stdenv.hostPlatform.system}'
  flake-inputs = final: _: {
    inputs =
      builtins.mapAttrs (
        _: flake: let
          legacyPackages = (flake.legacyPackages or {}).${final.stdenv.hostPlatform.system} or {};
          packages = (flake.packages or {}).${final.stdenv.hostPlatform.system} or {};
        in
          if legacyPackages != {}
          then legacyPackages
          else packages
      )
      inputs;
  };

  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev:
    (import ../pkgs {pkgs = final;})
    // {
      claude-code = final.callPackage ../pkgs/claude-code {};
      mise = final.callPackage ../pkgs/mise {};
      opencode = final.callPackage ../pkgs/opencode {};
      pi-coding-agent = final.callPackage ../pkgs/pi-coding-agent {};
    };

  sqlit-tui = final: prev: {
    sqlit-tui = prev.sqlit-tui.overridePythonAttrs (finalAttrs: previousAttrs: {
      version = "1.4.0";
      src = final.fetchFromGitHub {
        owner = "Maxteabag";
        repo = "sqlit";
        tag = "v${finalAttrs.version}";
        hash = "sha256-lcZe7EiN/wZllRO7KnXryoeGiUVBhSE4AYaRniZV6Cw=";
      };
      dependencies =
        previousAttrs.dependencies
        ++ [
          final.python3Packages.snowflake-connector-python
        ];
    });
  };

  # access stable packages as pkgs.stable
  stable-packages = final: _prev: {
    stable = import inputs.nixpkgs-stable {
      system = final.stdenv.hostPlatform.system;
      config = {
        allowUnfree = true;
        permittedInsecurePackages = [
          "electron-27.3.11"
        ];
      };
    };
  };
}
