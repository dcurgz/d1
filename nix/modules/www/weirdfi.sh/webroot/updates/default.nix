{
  inputs,
  ...
} @args:
let
  inherit (args.config) flake;
in

{
  flake.modules.nixos."weirdfi.sh-updates" = flake.lib.nixos.mkAspect (with flake.tags; [ flake-default ])
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
      std = inputs.nix-std.lib;
    in
    {
      config.by.www."weirdfi.sh".templates."updates" =
        let
          files = lib.filesystem.listFilesRecursive ./.;
          files-filtered = lib.pipe files [
            (builtins.filter (f: std.string.hasSuffix ".7" f))
          ];
          files-mapped = builtins.map (f: ''
            .It
            ${builtins.readFile f}
          '') files-filtered;
          files-str = lib.strings.join "\n" files-mapped;
        in
        ''
          .Bl -enum
          ${files-str}
          .El
        '';
    });
}
