{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    naersk = {
      url = "github:nix-community/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, flake-utils, naersk, nixpkgs, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        inherit (nixpkgs) lib;
        pkgs = (import nixpkgs) {
          inherit system;
        };

        naersk' = pkgs.callPackage naersk { };
        package = naersk'.buildPackage ./.;
      in
      {
        packages.default = package;
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [ rustc cargo ];
        };
      }
    ) // {
      nixosModules.default =
        {
          lib,
          pkgs,
          ...
        }:
        let
          microctl = self.packages.${pkgs.system}.default;
        in
        mkMerge
        [
          (import ./nixos/options { inherit lib microctl; })
          (import ./nixos/module { })
        ];
}
