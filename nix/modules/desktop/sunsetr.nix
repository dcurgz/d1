{
  inputs,
  ...
} @args:
let
  inherit (args.config) flake;
  inherit (args.config.by) git-secrets;
in

{
  flake.modules.home-manager.sunsetr = flake.lib.home-manager.mkAspect
  (with flake.tags; [ nixos-desktop ])
    ({
      lib,
      config,
      pkgs,
      ...
    }:

    let
      cfg = {
        package = inputs.sunsetr.packages.${pkgs.system}.default;
        settings = {
          inherit (git-secrets.cave) latitude longitude;
        };
      };
    in
    {
      systemd.user.services.sunsetr = {
        Unit = {
          Description = "Automatic blue-light filter for Hyprland, Niri, and everything Wayland ";
          After = [ config.wayland.systemd.target ];
          PartOf = [ config.wayland.systemd.target ];
          ConditionEnvironment = "WAYLAND_DISPLAY";
        };

        Service = {
          ExecStart =
            let
              toml = pkgs.formats.toml { };
              tomlFile = toml.generate "sunsetr.toml" cfg.settings;
              configDir = pkgs.linkFarm "sunsetr" [
                {
                  name = "sunsetr.toml";
                  path = tomlFile;
                }
              ];
            in
            "${cfg.package}/bin/sunsetr --config ${configDir}";
          };

          Install = {
            WantedBy = [ config.wayland.systemd.target ];
          };
        };

        home.packages = [ cfg.package ];
    });
}
