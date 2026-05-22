{
  inputs,
  config,
  ...
}:

let
  inherit (config) flake;
in
{
  flake.modules.nixos.desktop-xdg-compat = flake.lib.nixos.mkAspect (with flake.tags; [ nixos-desktop ])
    ({
      ...
    }:

    {
      environment.pathsToLink = [ "/share/applications" "/share/xdg-desktop-portal" ];
    }); 

  flake.modules.home-manager.desktop-xdg = flake.lib.home-manager.mkAspect (with flake.tags; [ nixos-desktop ])
    ({
      lib,
      config,
      pkgs,
      ...
    }:

    let
      browser = [ "firefox.desktop" ];
      image-viewer = [ "qiv.desktop" ];
    in
    {
      xdg = {
        portal = {
          enable = true;
          config.common = {
            default = [ "gnome" ];
          };
          xdgOpenUsePortal = true;
          extraPortals = with pkgs; [
            xdg-desktop-portal-gnome
            xdg-desktop-portal-gtk
            nautilus
          ];
        };
        mimeApps = {
          enable = true;
          defaultApplications = {
            "text/html" = browser;
            "x-scheme-handler/http" = browser;
            "x-scheme-handler/https" = browser;
            "x-scheme-handler/about" = browser;
            "x-scheme-handler/unknown" = browser;
            "image/png" = image-viewer;
            "image/jpg" = image-viewer;
            "image/jpeg" = image-viewer;
            "image/webp" = image-viewer;
            "image/svg+xml" = image-viewer;
          };
        };
      };

      home.packages = with pkgs; [
        xdg-utils
      ];
    });
}
