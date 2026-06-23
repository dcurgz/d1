{
  lib,
  pkgs,
  stdenvNoCC ? pkgs.stdenvNoCC,
  ...
}:

let
  sources = lib.pipe ./. [
    lib.filesystem.listFilesRecursive
    (builtins.filter (p: lib.strings.endsWith p.name ".nix"))
  ];
  args = { inherit lib pkgs; };
in
stdenvNoCC.mkDerivation {
  pname = "bin-nix-scripts";
  srcs  = builtins.map (f: 
    (pkgs.writeText f.name (import f args))
  ) sources;
  installPhase = ''
    mkdir -p $out/bin
    cp -v $src/* $out/bin
    chmod ug+x $out/bin
  '';
}
