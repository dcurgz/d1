{
  inputs,
  ...
} @args:
let
  inherit (args.config) flake;
in

{
  flake.modules.nixos.nix-access-token = flake.lib.nixos.mkAspect
    (with flake.tags; [ nixos-privileged ])
    ({
      lib,
      config,
      ...
    }:

    {
      age.secrets.nix-github-access-token.file =
        "${inputs.agenix-secrets}/agenix/nix/github-access-token.age";
      nix.extraOptions = ''
        !include ${config.age.secrets.nix-github-access-token.path}
      '';
    });
}
