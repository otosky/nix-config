{
  outputs,
  lib,
  config,
  pkgs,
  ...
}: let
  hostnames = builtins.attrNames outputs.nixosConfigurations;
in {
  programs.ssh = {
    enable = true;
    matchBlocks = {
      net = {
        host = builtins.concatStringsSep " " hostnames;
        forwardAgent = true;
        remoteForwards = [
          {
            bind.address = ''/%d/.gnupg-sockets/S.gpg-agent'';
            host.address = ''/%d/.gnupg-sockets/S.gpg-agent.extra'';
          }
        ];
      };
      trusted = lib.hm.dag.entryBefore ["net"] {
        host = "github.com";
        forwardAgent = true;
      };
      brocade = lib.hm.dag.entryAfter ["net"] {
        host = "brocade.toskbot.xyz";
        extraOptions = {
          KexAlgorithms = "+diffie-hellman-group1-sha1";
          PubkeyAcceptedKeyTypes = "+ssh-rsa";
          HostKeyAlgorithms = "+ssh-rsa";
          IdentityAgent = "~/.1password/agent.sock";
        };
      };
      kube = lib.hm.dag.entryAfter ["brocade"] {
        host = "kube*.toskbot.xyz";
        extraOptions = {
          IdentityAgent = "~/.1password/agent.sock";
        };
      };
    };
  };

  home.persistence = {
    "/persist/home/olivertosky".directories = [".ssh"];
  };
}
