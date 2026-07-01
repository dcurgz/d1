{
  inputs,
  ...
} @args:
let
  inherit (args.config) flake;
in

{
  flake.modules.nixos."weirdfi.sh-index" = flake.lib.nixos.mkAspect (with flake.tags; [ flake-default ])
    ({
      lib,
      config,
      pkgs,
      ...
    }:

    let
      inherit (pkgs.by.lib) replaceOptionalVars;
      cfg = config.by.www."weirdfi.sh";
      inherit (cfg) templates;
      lib' = cfg.lib;
    in
    {
      config.by.www."weirdfi.sh".pages = [
        {
          title = "WEIRDFI.SH";
          description = "Site Index";
          date = "2026-05-12";
          slug = "/";
          permalink = null;
          src = lib.pipe ./index.7 [
            (path: replaceOptionalVars path templates)
            (path: lib'.renderMdoc "index.html" path)
          ];
        }
      ];
    });
}
