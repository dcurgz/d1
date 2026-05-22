{
  inputs,
  lib,
  config,
  prebuiltPackages,
  ...
}:

{
  perSystem =
    {
      system,
      ...
    }:

    let
      pkgs = prebuiltPackages.${system};
    in
    {
      packages.flakegraph = pkgs.runCommand "render-flakegraph" 
        {
          nativeBuildInputs = with pkgs; [ plantuml ];
        }
        (let
          plantuml = import ./_plantuml.nix {
            inherit lib;
            hosts = config.flake.metadata;
          };
          plantumlSrc = pkgs.writeText "plantuml-src" plantuml;
        in
        ''
          export XDG_CACHE_HOME="$(mktemp -d)" 
          mkdir -p $out
          cat ${plantumlSrc} > $out/hosts.plantuml
          cat ${plantumlSrc} | plantuml -p > $out/hosts.png
        '');
    };
}
