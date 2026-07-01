{
  inputs,
  ...
} @args:
let
  inherit (args.config) flake;
in

{
  flake.modules.nixos."weirdfi.sh-001-introductions" = flake.lib.nixos.mkAspect (with flake.tags; [ flake-default ])
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
          title = "001-introductions";
          description = "A little bit of context.";
          date = "2026-07-01";
          slug = "/posts/001-introductions/";
          permalink = null;
          src = lib.pipe ./default.7 [
            (path: replaceOptionalVars path templates)
            (path: lib'.renderMdoc "index.html" path)
          ];
        }
      ];
    });
}
