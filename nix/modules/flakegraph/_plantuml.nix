{
  lib,
  hosts,
}:

let
  mkOrder = nodes:
    let
      nodePairs = lib.lists.zipLists
        nodes
        (lib.lists.takeEnd ((builtins.length nodes) - 1) nodes);
      nodeOrder = builtins.map ({ fst, snd }:
        # Use a hidden arrow to force top-to-bottom ordering.
        ''
          "${fst}" -d[hidden]-> "${snd}"
        '') nodePairs;
    in
      lib.strings.join "\n" nodeOrder;

  nodes = lib.mapAttrsToList (hostName: host:
    let
      uplinks = lib.mapAttrsToList (interfaceName: uplink:
        "${interfaceName} ${uplink.ipAddress}") host.attributes.uplinks;
      uplinksIndexed = lib.lists.zipLists
        uplinks
        (lib.lists.range 0 999);
      uplinkComponents = builtins.map ({ fst, snd }: ''
        ["U-${hostName}-${toString snd}"] as "${fst}"
      '') uplinksIndexed;

      services = if (host.attributes.services != null) then
          (builtins.attrNames host.attributes.services)
        else
          [ ];
      servicesIndexed = lib.lists.zipLists
        services
        (lib.lists.range 0 999);
      serviceComponents = builtins.map ({ fst, snd }: ''
        ["S-${hostName}-${toString snd}"] as "${fst}"
      '') servicesIndexed;
    in
    ''
      node "${hostName}" {
        ${lib.strings.join "\n" serviceComponents}
        ${lib.strings.join "\n" uplinkComponents}
      }

      note right of "${hostName}"
        ${host.description}
      end note
    '') hosts;

  hostNames = builtins.attrNames hosts;
in
''
  ${lib.strings.join "\n" nodes}
  ${mkOrder hostNames}
''
