{
  inputs,
  lib,
  globals,
  prebuiltPackages,
  ...
} @args:

let
  inherit (globals) FLAKE_ROOT;
  inherit (args.config) flake;
  inherit (args.config.by) keys git-secrets;
in
{
  flake.robotnixConfigurations.midnight = inputs.robotnix.lib.robotnixSystem (
    {
      pkgs,
      ...
    }:
    
    {
      flavor = "grapheneos";   
      device = "shiba"; # Pixel 8

      grapheneos = {
        channel = "beta";
      };

      # Enable F-Droid.
      apps.fdroid.enable = true;
      apps.fdroid.additionalRepos = import ./fdroid.nix;

      # Enable updater.
      apps.updater = {
        enable = true;
        url = "https://ota.weirdfi.sh/midnight";
      };

      # Uses /var/cache/ccache impurely.
      ccache.enable = true;

      stateVersion = "3";
    });
}
