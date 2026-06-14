{
  inputs,
  globals,
  ...
} @args:
let
  inherit (args.config) flake;
  inherit (globals) FLAKE_ROOT;
in

{
  flake.modules.nixos.hyperberry-jenkins = flake.lib.nixos.mkAspect []
    ({
      lib,
      config,
      pkgs,
      ...
    }:

    {
      age.secrets.jenkins-gpg-key = {
        file = "${FLAKE_ROOT}/agenix-secrets/agenix/hyperberry/jenkins-gpg-key.age";
        mode = "770";
        owner = "jenkins";
        group = "root";
      }; 

      services.jenkins = {
        enable = true;
        packages = with pkgs; [
          bashInteractive
          cacert
          coreutils
          git
          gnupg
          lix
        ];
        environment = {
          SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        };
        jobBuilder.enable = true;
        jobBuilder.nixJobs = [
          {
            job = {
              name = "grapheneos-weekly";
              builders = [
                {
                  shell = builtins.readFile ./grapheneos-weekly.sh;
                }
              ];
            };
          }
        ];
      };
    });
}
