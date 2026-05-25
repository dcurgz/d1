{
  inputs,
  ...
} @args:
let
  inherit (args.config) flake;
in

{
  flake.modules.nixos."dcurgz.me-001-NixOS" = flake.lib.nixos.mkAspect (with flake.tags; [ flake-default ])
    ({
      lib,
      config,
      pkgs,
      ...
    }:

    let
      inherit (pkgs.by.lib) replaceOptionalVars;
      cfg = config.by.www."dcurgz.me";
      inherit (cfg) templates;
      lib' = cfg.lib;
    in
    {
      config.by.www."dcurgz.me".pages = [
        rec {
          title = "My experience with Nix";
          description = "Or: how to lose your mind in 13 months.";
          tags = [ "#nix" "#linux" "#self-hosting" ];
          date = "2026-05-22";
          slug = "/posts/NixOS/";
          permalink = "/posts/bOYncvZFFb/";
          src = lib.pipe ./001-experience-with-nix.7 [
            (path: replaceOptionalVars path {
              inherit title description slug permalink;
            })
            (path: replaceOptionalVars path templates)
            (path: lib'.renderMdoc "index.html" path)
          ];
        }
      ];
    });
}
