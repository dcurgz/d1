{
  inputs,
  ...
} @args:
let
  inherit (args.config) flake;
in

{
  # Install to flake-default; jaspine.me is enabled based on the uppermost module.
  flake.modules.nixos."jaspine.me-webroot" = flake.lib.nixos.mkAspect (with flake.tags; [ flake-default ])
    ({
      lib,
      config,
      pkgs,
      ...
    }:

    let
      inherit (pkgs) stdenv;
      inherit (inputs) nix-time;

      inherit (pkgs.by.lib) replaceOptionalVars;

      domain = "jaspine.me";
    in
    {
      options.by.www.${domain} = {
        pages = lib.mkOption {
          type = lib.types.listOf (lib.types.submodule {
            options = {
              title       = lib.mkOption { type = lib.types.str; };
              description = lib.mkOption { type = lib.types.str; };
              tags        = lib.mkOption { type = lib.types.listOf lib.types.str; };
              date        = lib.mkOption { type = lib.types.str; };
              slug        = lib.mkOption { type = lib.types.str; };
              permalink   = lib.mkOption { type = lib.types.nullOr lib.types.str; };
              src         = lib.mkOption { type = lib.types.package; };
            };
          });
        };
      };

      config.by.websites.sites.${domain}.web-server.webroot = pkgs.linkFarm "${domain}-webroot" [
        {
          name = "index.html";
          path = ./index.html;
        }
      ];
    });
}
