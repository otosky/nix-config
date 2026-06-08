# This file defines overlays
{inputs, ...}: {
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
      claude-code = inputs.llm-agents.packages.${final.stdenv.hostPlatform.system}.claude-code;
      codex = inputs.llm-agents.packages.${final.stdenv.hostPlatform.system}.codex;
      herdr = inputs.herdr.packages.${final.stdenv.hostPlatform.system}.herdr;
      mise = final.callPackage ../pkgs/mise {};
      opencode = inputs.llm-agents.packages.${final.stdenv.hostPlatform.system}.opencode;
      pi-coding-agent = inputs.llm-agents.packages.${final.stdenv.hostPlatform.system}.pi;
    };

  # access stable packages as pkgs.stable
  stable-packages = final: _prev: {
    stable = import inputs.nixpkgs-stable {
      system = final.stdenv.hostPlatform.system;
      config = {
        allowUnfree = true;
        permittedInsecurePackages = [
          "electron-39.8.10"
        ];
      };
    };
  };
}
