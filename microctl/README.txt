MICROCTL

A MicroVM management daemon and CLI for microvm.nix deployments.

Not yet functional.

ROADMAP

[x] CLI: stubs
    [ ] microctl list|ls|l
        (List all MicroVM nodes.)
    [ ] microctl start <id>
        (Start a MicroVM node.)
    [ ] microctl stop [--kill | -k] <id>
        (Stop a MicroVM node.)
    [ ] microctl restart [--kill | -k] <id>
        (Restart a MicroVM node.)
    [ ] microctl info <id>
        (Get information about a MicroVM node.)
    [ ] microctl configure <id>
        (Override declarative node configuration.)
        [ ] --auto-run y|n,     default: y
            (When a new node is added to the configuration, start it automatically.)
        [ ] --auto-upgrade y|n, default: y
            (When a node has its runner derivation replaced, stop the old instance, then start the new one automatically.)
        [ ] --auto-delete y|n,  default: y
            (When a node is removed from the configuration, stop it automatically.)
    [ ] microctl reload
        (Tell the daemon to reload its node configuration.)
[x] microctld: local net bind socket
[ ] microctld: stateless db + lockfile
    [ ] check lockfile is stale (lockfile pid is dead)
[ ] microctld: node configuration (JSON)
[ ] microctl-options: nix DSL for node configuration
[ ] microctl-options: systemd definition for microctld
[ ] microctl-options: systemd definition for Nix activation
