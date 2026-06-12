{
  inputs,
  ...
} @args:
let
  inherit (args.config) flake;

  # Seems like mirrors don't work anymore.
  #mirrors = {
  #  "https://android.googlesource.com" = "/var/cache/git-mirrors/android";
  #  "https://github.com/GrapheneOS" = "/var/cache/git-mirrors/grapheneos";
  #};

  ccache_path = "/var/cache/ccache";
in

{
  #https://docs.robotnix.org/development.html?highlight=mirror#git-mirrors
  flake.modules.nixos.robotnix-host = flake.lib.nixos.mkAspect []
    ({
      lib,
      config,
      ...
    }:

    {
      #nix.envVars.ROBOTNIX_GIT_MIRRORS = lib.concatStringsSep "|" (lib.mapAttrsToList (local: remote: "${local}=${remote}") mirrors);

        nix.settings = {
          #extra-sandbox-paths = lib.attrvalues mirrors ++ [ ccache_path ];
          extra-sandbox-paths = [ ccache_path ];

          # Binary cache for device kernels and browsers, provided by Robotnix project.
          substituters = [ "https://robotnix.cachix.org" ];
          trusted-public-keys = [ "robotnix.cachix.org-1:+y88eX6KTvkJyernp1knbpttlaLTboVp4vq/b24BIv0=" ];
        };
    });
}
