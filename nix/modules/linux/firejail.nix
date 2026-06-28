{
  inputs,
  ...
} @args:
let
  inherit (args.config) flake;
in

{
  flake.modules.nixos.firejail = flake.lib.nixos.mkAspect
    (with flake.tags; [ nixos-base ])
    ({
      lib,
      config,
      ...
    }:

    {
      programs.firejail.enable = true;
    });
}
