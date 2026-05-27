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
