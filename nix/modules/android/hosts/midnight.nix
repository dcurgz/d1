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
  flake.robotnixConfigurations.midnight = flake.lib.mkAOSP {
    modules = with flake.modules; [
      # Install OpenSSH daemon
      android.openssh
      # Configure authorized keys
      {
        sshd.authorizedKeys = {
          # Allow all privileged keys to login as root.
          root = keys.ssh.groups.privileged.paths;
        };
      }
      # Device configuration
      {
        flavor = "grapheneos";
        device = "shiba"; # Pixel 8
        deviceDisplayName = "midnight";

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

        # Enable custom boot "animation".
        bootanimation = {
          enable = true;
          logoMask = ./android-logo-mask.png;
          logoShine = ./android-logo-shine.png;
        };

        # Uses /var/cache/ccache impurely.
        ccache.enable = true;

        stateVersion = "3";
        buildDateTime = inputs.self.lastModified;
      }
    ];
  };
}
