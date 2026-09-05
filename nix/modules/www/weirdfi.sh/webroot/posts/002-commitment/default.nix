{
  inputs,
  ...
} @args:
let
  inherit (args.config) flake;
in

{
  flake.modules.nixos."weirdfi.sh-002-commitment" = flake.lib.nixos.mkAspect (with flake.tags; [ flake-default ])
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
        rec {
          title = "002-commitment";
          description = "Understanding my relationship with commitment";
          date = "2026-09-03";
          slug = "/posts/002-commitment/";
          permalink = null;
          src = lib.pipe ./default.7 [
            (path: replaceOptionalVars path templates)
            (path: replaceOptionalVars path { inherit title description; })
            (path: lib'.renderMdoc "index.html" path)
          ];
        }
      ];
    });
}
