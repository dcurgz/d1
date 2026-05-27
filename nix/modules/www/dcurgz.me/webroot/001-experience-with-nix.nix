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

      flake-simple = ''
        # flake.nix
        {
          inputs = {
            # The last part of the URL here describes the Git branch for nixpkgs.
            nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
          };

          outputs = inputs: {
            nixosConfigurations.your-server = inputs.nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              modules = [
                # This is short for ./systems/your-server/default.nix.
                ./systems/your-server 
                # This file doesn't exist yet, as it will be generated inside
                # the installer environment.
                ./systems/your-server/hardware-configuration.nix
              ];
            };
          };
        }
      '';
      flake-simple' = lib'.renderCode {
        name = "flake-simple-rendered";
        lang = "nix";
        path = pkgs.writeText "flake-simple" flake-simple;
      };

      flake-default = ''
        # ./systems/your-server/default.nix
        {
          lib,
          pkgs,
          config,
          ...
        }:

        {
          ### Humble beginnings.
          networking.hostName = "your-server";

          # This means something important, but nobody knows what.
          system.stateVersion = "25.05";
        }
      '';
      flake-default' = lib'.renderCode {
        name = "flake-default-rendered";
        lang = "nix";
        path = pkgs.writeText "flake-default" flake-default;
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
              inherit flake-schema' flake-simple' flake-default';
            })
            (path: replaceOptionalVars path templates)
            (path: lib'.renderMdoc "index.html" path)
          ];
        }
      ];
    });
}
