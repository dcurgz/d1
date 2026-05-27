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
