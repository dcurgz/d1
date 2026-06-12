{
  inputs,
  lib,
  ...
} @args:

# A set of baseline packages that should be present everywhere.
let
  inherit (args.config) flake;

  mkPackages = system: pkgs: with pkgs; [
    git-repo
    #androidsdk
    #android-tools
  ];
in
{
  flake.modules.nixos.packages-android = flake.lib.nixos.mkAspect [ ]
    ({
      lib,
      config,
      pkgs,
      ...
    }:

    {
      environment.systemPackages = mkPackages pkgs.system pkgs;
    });

  flake.modules.darwin.packages-android = flake.lib.darwin.mkAspect [ ]
    ({
      lib,
      config,
      pkgs,
      ...
    }:

    {
      environment.systemPackages = mkPackages pkgs.system pkgs;
    });

  # Intended for standalone home-manager deployments, though I don't use this ATM.
  flake.modules.home-manager.packages-android = flake.lib.home-manager.mkAspect []
    ({
      lib,
      config,
      pkgs,
      ...
    }:

    {
      home.packages = mkPackages pkgs.system pkgs;
    });
}
