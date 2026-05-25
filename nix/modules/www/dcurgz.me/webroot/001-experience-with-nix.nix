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

      flake-schema = ''
        {
          description = "This is a Nix flake.";

          inputs = {
            # The flake inputs are a set of instructions for fetching the
            # dependencies of a flake. The Nix tooling can use these inputs to
            # build flake outputs, and do dependency management via the
            # `flake.lock` file.
            some-input = {
              url = "github:repo_owner/repo_name";
            };
          };

          outputs = inputs: {
            # All flake outputs are defined within this attribute set. The
            # outputs are evaluated as a function of the flake inputs.
            nixosConfigurations = {
              # Each attribute in this attribute set is a NixOS system
              # configuration, created by `nixpkgs.lib.nixosSystem`.
            };

            packages = {
              # In each of these 'system' attributes, an attribute set of
              # packages can be defined. A package is something that can be
              # built by the Nix daemon into a store path, which is just a
              # read-only folder of arbitrary files. A store path looks like
              # `/nix/store/qw42xnf5i6gfwsk2nm6pq5mxkqdazwn3-[name]`, where the
              # first part is a hash of the inputs to the build process. This
              # means the same package definition, with the same dependency
              # versions, results in an identical store path. This is what
              # underpins reproducibility on NixOS.
              x86_64-linux   = { ... };
              x86_64-darwin  = { ... };
              aarch64-linux  = { ... };
              aarch64-darwin = { ... };
              # ...there are more, but these are the main supported ones.
            };

            devShells = {
              # An attribute set of development shell definitions, which are
              # consumed by the `nix develop` command-line tool. A system
              # running the Nix daemon (not necessarily NixOS) can install and
              # build shell dependencies into store paths, and then construct a
              # virtual environment (a chroot) so that the relevant binaries
              # are available under `$PATH`. You can use this to build software.
            };

            # ...there are more output types. See the NixOS manual for more.
          };
        }
      '';
      flake-schema' = lib'.renderCode {
        name = "flake-schema-rendered";
        lang = "nix";
        path = pkgs.writeText "flake-schema" flake-schema;
      };
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
              inherit flake-schema';
            })
            (path: replaceOptionalVars path templates)
            (path: lib'.renderMdoc "index.html" path)
          ];
        }
      ];
    });
}
