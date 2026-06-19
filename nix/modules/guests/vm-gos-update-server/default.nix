{
  inputs,
  lib,
  ...
} @args:

let
  inherit (args.config) flake;

  hostName = "vm-gos-update-server";
  images_dir = "/data/gos-update-server";

  public_address = "ota.weirdfi.sh";
in
{
  flake.modules.nixos.${hostName} = flake.lib.nixos.mkMicroVM
    rec {
      enable = true;
      inherit hostName;
      system = "x86_64-linux";
      extraModules = [
        ### aspects
        ### 3rd party modules
        inputs.agenix.nixosModules.default
      ];
      microvmConfig = {
        networking = {
          macAddress = "02:00:00:00:00:16";
          ipAddress = "10.0.0.26";
        };
        tailscale = {
          enable = true;
          autologin = true;
        };
      };
      tags = with flake.tags; [ ];
    }

    ({
      config,
      pkgs,
      ...
    }:

    let
      secrets = config.by.git-secrets;
      frontend_hostname = secrets.hosts.${hostName}.ssh.hostName;
    in
    {
      age.secrets.cloudflare-key.file = "${inputs.agenix-secrets}/agenix/weirdfi.sh/cloudflare-key.age";

      microvm.vcpu = 1;
      microvm.mem = 1024 * 1 + 1;
      microvm.shares = [
        # gos-update data directory
        {
          source = images_dir;
          mountPoint = images_dir;
          tag = "gos-images-dir";
          proto = "virtiofs";
          socket = "gos-images-dir.sock";
        }
        # SSL certificates
        {
          source = "/etc/ssl/certs";
          mountPoint = "/etc/ssl/certs";
          tag = "ssl-certs";
          proto = "virtiofs";
          socket = "ssl-certs.sock";
        }
        # This is needed to prevent continuous registration of the same ACME account.
        {
          source = "/var/lib/microvms/${config.networking.hostName}/acme";
          mountPoint = "/var/lib/acme";
          tag = "acme";
          proto = "virtiofs";
          socket = "acme.sock";
        }
      ];

      nix.channel.enable = false;

      services.nginx =
        let
          tailscale_address = secrets.hosts.vm-gos-update-server.ssh.hostName;
        in
        {
          enable = true;
          recommendedProxySettings = true;
          recommendedGzipSettings = true;
          recommendedOptimisation = true;
          recommendedTlsSettings = true;
          virtualHosts.${tailscale_address} = {
            forceSSL = true;
            sslCertificate = "/etc/ssl/certs/${tailscale_address}.crt";
            sslCertificateKey = "/etc/ssl/certs/${tailscale_address}.key";
            locations."/midnight" = {
              root = images_dir;
              tryFiles = "$uri $uri/ =404";
              extraConfig = ''
                autoindex on;
              '';
            };
          };

          virtualHosts.${public_address} = {
            default = true;
            forceSSL = true;
            useACMEHost = public_address;
             # Disable ACME challenge generation to force DNS-01.
            acmeRoot = null;
            locations."/midnight" = {
              root = images_dir;
              tryFiles = "$uri $uri/ =404";
              extraConfig = ''
                autoindex on;
              '';
            };
          };
        };

       security.acme = {
         acceptTerms = true;
         defaults.email = secrets.weirdfish-acme.email;
         certs = {
           ${public_address} = {
             domain = public_address;
             #extraDomainNames = [ "*.${public_address}" ];
             group = "nginx";
             dnsProvider = "cloudflare";
             # location of your CLOUDFLARE_DNS_API_TOKEN=[value]
             environmentFile = config.age.secrets.cloudflare-key.path;
           };
         };
       };

       users.users.nginx.extraGroups = [ "data" ]; # for certs

       networking.firewall.allowedTCPPorts = [
         22
         80
         443
       ];
     });
}
