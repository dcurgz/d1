{
  lib,
  microctl,
}:
let
  nodeSettings = {
    autoCreate = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Start this node automatically when it is added to the configuration.";
    };
    autoUpgrade = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Restart this node automatically when its runner derivation changes.";
    };
    autoDelete = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Stop this node automatically when it is removed from the configuration.";
    };
  };

  nodeConfig = lib.types.submodule ({ name, ... }: {
    options = {
      runner = lib.mkOption {
        type = lib.types.path;
        description = "Path to the runner derivation for this node.";
      };
      settings = nodeSettings;
    };
  });
in
{
  options.services.microctld = {
    enable = lib.mkEnableOption "microctld, the MicroVM management daemon";

    package = lib.mkOption {
      type = lib.types.package;
      default = microctl;
      defaultText = lib.literalExpression "microctl";
      description = "The microctl package to use.";
    };

    nodes = lib.mkOption {
      type = lib.types.attrsOf nodeConfig;
      default = { };
      description = "MicroVM nodes managed by microctld. The attribute name is used as the node ID.";
    };
  };
}
