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

      age.secrets.jjb-token = {
        file = "${FLAKE_ROOT}/agenix-secrets/agenix/hyperberry/jjb-token.age";
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
          git-crypt
          gnumake
          gnupg
          lix
        ];
        environment = {
          SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        };
        jobBuilder.enable = true;
        jobBuilder.accessUser = "jjb";
        jobBuilder.accessTokenFile = config.age.secrets.jjb-token.path;
        jobBuilder.nixJobs = [
          {
            job = {
              name = "grapheneos-weekly";
              triggers.timed = "0 3 * * MON";
              builders = [
                {
                  shell = builtins.readFile ./grapheneos-weekly.sh;
                }
              ];
            };
          }
        ];
      };

      users.users.jenkins.extraGroups = [ "data" ];

      systemd.paths.grapheneos-release-watch = {
        wantedBy = [ "multi-user.target" ];
        pathConfig = {
          Unit = "grapheneos-release-publish.service";
          PathChanged = "/var/lib/jenkins/workspace/grapheneos-weekly/releases/latest";
        };
      };
      
      systemd.services.grapheneos-release-publish = {
        enable = true;
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeScript "publish-gos-release" ''
            #!/${pkgs.bash}/bin/bash
            SRC=/var/lib/jenkins/workspace/grapheneos-weekly/releases/latest
            REALPATH=$(readlink -f $SRC)
            echo $REALPATH
            BUILDNO=$(basename $REALPATH)

            DEST="/data/gos-update-server/midnight.$BUILDNO"
            cp -rLv "$SRC" "$DEST"

            chmod -R 770 $DEST
            chown -R root:data $DEST

            OUT=/data/gos-update-server/midnight
            LINK=/data/gos-update-server/midnight.tmp
            ln -s $DEST $LINK
            mv -T $LINK $OUT
          '';
        };
      };
    });
}
