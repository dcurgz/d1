{
  inputs,
  ...
} @args:
let
  inherit (args.config) flake;
in

{
  flake.modules.nixos."weirdfi.sh" = flake.lib.nixos.mkAspect []
    ({
      lib,
      config,
      ...
    }:

    let
      secrets = config.by.secrets.weirdfish;
      ports   = config.by.portmap;

      domain = "weirdfi.sh";
    in
    {
      config.by.websites.enable = true;
      config.by.websites.debug = true;
      config.by.websites.sites.${domain} = {
        inherit domain;
        acme.enable = true;
        cloudflare.enable = true;
        anubis = {
          enable = true;
          ports = {
            bind = ports.internal.anubis;
            target = ports.internal.nginx;
          };
        };
        web-server = {
          enable = true;
          # webroot is defined under ./webroot
        };
      };
    });
}
