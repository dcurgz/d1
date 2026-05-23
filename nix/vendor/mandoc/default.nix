{
  pkgs ? import <nixpkgs> { },
  lib ? (import <nixpkgs> { }).lib,
  ...
}:

pkgs.mandoc.overrideAttrs (final: prev:
  let
    patches = lib.filesystem.listFilesRecursive ./patches;
  in
  {
    pname = "mandoc-fork";

    nativeBuildInputs = with pkgs; [ git ];
    preBuild = (prev.preBuild or "") +
      lib.pipe patches [
        (builtins.map (path: "git apply ${path}"))
        (lib.strings.join "\n")
      ];
  })
