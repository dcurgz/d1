{
  inputs,
  lib,
  globals,
  prebuiltPackages,
  ...
} @args:

let
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
      apps.fdroid.additionalRepos = import ./_fdroid.nix;

      # Enable updater.
      apps.updater = {
        enable = true;
        url = "https://ota.weirdfi.sh/midnight";
      };

      # Patch in custom logo for Android boot animation.
      source.dirs."frameworks/base".postPatch =
        let
          android-logo-mask  = ./android-logo-mask.png;
          android-logo-shine = ./android-logo-shine.png;
        in
        ''
          cp -rv ${android-logo-mask} ./core/res/assets/images/android-logo-mask.png
          cp -rv ${android-logo-shine} ./core/res/assets/images/android-logo-shine.png
        '';

      # Uses /var/cache/ccache impurely.
      ccache.enable = true;

      stateVersion = "3";
      buildDateTime = inputs.self.lastModified;
    });
}
