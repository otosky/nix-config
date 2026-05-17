{
  _1password-cli,
  bats,
  coreutils,
  fzf,
  gnugrep,
  gnused,
  lib,
  runCommand,
  shellcheck,
  usql,
  writeShellApplication,
  yq,
}: let
  usqlp = writeShellApplication {
    name = "usqlp";

    runtimeInputs = [
      _1password-cli
      coreutils
      fzf
      usql
      yq
    ];

    text = builtins.readFile ./usqlp.sh;
  };

  tests =
    runCommand "usqlp-tests" {
      nativeBuildInputs = [
        bats
        coreutils
        gnugrep
        gnused
        shellcheck
      ];
    } ''
      shellcheck ${./usqlp.sh} ${./test.bats}
      export USQLP_BIN=${usqlp}/bin/usqlp
      bats ${./test.bats}
      touch $out
    '';
in
  usqlp.overrideAttrs (oldAttrs: {
    passthru =
      (oldAttrs.passthru or {})
      // {
        inherit tests;
      };

    meta =
      (oldAttrs.meta or {})
      // {
        description = "uSQL wrapper with lazy 1Password config injection and fzf connection picking";
        mainProgram = "usqlp";
        platforms = lib.platforms.unix;
      };
  })
