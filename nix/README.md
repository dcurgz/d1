## d1/nix: Jasper's Nix configuration

This is the base directory for jaspine's homelab configuration. Using Nix flakes
as dependency management and as a public interface, this config defines a
number of declarative system configurations to support self-hosted services and
personal machines.

This flake uses [flake-parts](https://flake.parts/), which means every Nix file
under `./modules` is a flake-parts module. flake-parts allows you to declare
flake attributes from any file in a Nix flake to keep things isolated and
maintainable.

## Hosts

| Hostname | Path | Description |
| --- | --- | --- |
| hyperberry | [./modules/hosts/hyperberry/default.nix](https://github.com/jaspine/d1/tree/master/nix/modules/hosts/hyperberry/default.nix) | Primary x86-64 Linux server. Hosts ~15 virtual machines to isolate personal services. |
| blueberry | [./modules/hosts/blueberry/default.nix](https://github.com/jaspine/d1/tree/master/nix/modules/hosts/blueberry/default.nix) | Primary x86-64 Linux desktop. For gaming and development. |
| piberry | [./modules/hosts/piberry/default.nix](https://github.com/jaspine/d1/tree/master/nix/modules/hosts/piberry/default.nix) | Raspberry Pi 4B running NixOS. Hosts home-assistant instance for home automation e.g. lights. |
| tauberry | [./modules/hosts/tauberry/default.nix](https://github.com/jaspine/d1/tree/master/nix/modules/hosts/tauberry/default.nix) | Raspberry Pi 4B running NixOS. Originally provisioned as a Hi-Fi audio server, currently not in use. |
| airberry | [./modules/hosts/airberry/default.nix](https://github.com/jaspine/d1/tree/master/nix/modules/hosts/airberry/default.nix) | Macbook Air M2 running MacOS (nix-darwin). Daily driver for remote development. |
| miniberry | [./modules/hosts/miniberry/default.nix](https://github.com/jaspine/d1/tree/master/nix/modules/hosts/miniberry/default.nix) | Macbook Mini M4 running MacOS (nix-darwin). Serves as a build server for aarch64-{linux, darwin} targets. |
| fooberry | [./modules/hosts/fooberry/default.nix](https://github.com/jaspine/d1/tree/master/nix/modules/hosts/fooberry/default.nix) | An old Intel laptop. Runs a reverse proxy for a media server. |

### Cloud servers

| Hostname | Path | Description |
| --- | --- | --- |
| weirdfish-cax11-4gb | [./modules/hosts/weirdfish-cax11-4gb/default.nix](https://github.com/jaspine/d1/tree/master/nix/modules/hosts/weirdfish-cax11-4gb/default.nix) | Hosts my personal blog, [jaspine.me](https://jaspine.me/). |
| publicproxy-cax11-4gb | [./modules/hosts/publicproxy-cax11-4gb/default.nix](https://github.com/jaspine/d1/tree/master/nix/modules/hosts/publicproxy-cax11-4gb/default.nix) | Simple reverse proxy for various self-hosted services e.g. Minecraft servers. |

## Guests

| Guest | Path | Description |
| --- | --- | --- |
| vm-claude | [./modules/guests/vm-claude/default.nix](https://github.com/jaspine/d1/tree/master/nix/modules/guests/vm-claude/default.nix) | An isolated VM for running Claude Code (et al) securely. |
| vm-gos-update-server | [./modules/guests/vm-gos-update-server/default.nix](https://github.com/jaspine/d1/tree/master/nix/modules/guests/vm-gos-update-server/default.nix) | Hosts an Nginx server to update `midnight` over-the-air. |
| vm-immich | [./modules/guests/vm-immich/default.nix](https://github.com/jaspine/d1/tree/master/nix/modules/guests/vm-immich/default.nix) | A self-hosted Google photos alternative. ([immich.app](https://immich.app/)) |
| vm-jellyfin | [./modules/guests/vm-jellyfin/default.nix](https://github.com/jaspine/d1/tree/master/nix/modules/guests/vm-jellyfin/default.nix) | A self-hosted media server ([jellyfin.org](https://jellyfin.org/)) |
| vm-mb-build-aarch64 | [./modules/guests/vm-mb-build-aarch64/default.nix](https://github.com/jaspine/d1/tree/master/nix/modules/guests/vm-mb-build-aarch64/default.nix) | An aarch64-linux builder VM. |
| vm-mc-leedlemon-0 | [./modules/guests/vm-mc-leedlemon-0/default.nix](https://github.com/jaspine/d1/tree/master/nix/modules/guests/vm-mc-leedlemon-0/default.nix) | A declarative Minecraft server. (prod) |
| vm-mc-leedlemon-1 | [./modules/guests/vm-mc-leedlemon-1/default.nix](https://github.com/jaspine/d1/tree/master/nix/modules/guests/vm-mc-leedlemon-1/default.nix) | A declarative Minecraft server. (preprod) |
| vm-mc-slime-0 | [./modules/guests/vm-mc-slime-0/default.nix](https://github.com/jaspine/d1/tree/master/nix/modules/guests/vm-mc-slime-0/default.nix) | A declarative Minecraft server. (prod) |
| vm-mc-slime-1 | [./modules/guests/vm-mc-slime-1/default.nix](https://github.com/jaspine/d1/tree/master/nix/modules/guests/vm-mc-slime-1/default.nix) | A declarative Minecraft server. (preprod) |
| vm-mc-wg-0 | [./modules/guests/vm-mc-wg-0/default.nix](https://github.com/jaspine/d1/tree/master/nix/modules/guests/vm-mc-wg-0/default.nix) | A declarative Minecraft server. (prod) |
| vm-mc-wg-1 | [./modules/guests/vm-mc-wg-1/default.nix](https://github.com/jaspine/d1/tree/master/nix/modules/guests/vm-mc-wg-1/default.nix) | A declarative Minecraft server. (preprod) |
| vm-openwebui | [./modules/guests/vm-openwebui/default.nix](https://github.com/jaspine/d1/tree/master/nix/modules/guests/vm-openwebui/default.nix) | A self-hosted LLM chat web application. ([github.com](https://github.com/open-webui/open-webui)) |
| vm-teamspeak | [./modules/guests/vm-teamspeak/default.nix](https://github.com/jaspine/d1/tree/master/nix/modules/guests/vm-teamspeak/default.nix) | Teamspeak 6 server for Voice-Over-IP. ([teamspeak.com](https://www.teamspeak.com/en/)) |
| vm-trilium | [./modules/guests/vm-trilium/default.nix](https://github.com/jaspine/d1/tree/master/nix/modules/guests/vm-trilium/default.nix) | A self-hosted note taking application. ([triliumnotes.org](https://triliumnotes.org/)) |
| vm-vikunja | [./modules/guests/vm-vikunja/default.nix](https://github.com/jaspine/d1/tree/master/nix/modules/guests/vm-vikunja/default.nix) | A self-hosted TODO application. ([vikunja.io](https://vikunja.io/)) |

### Mobile phones

| Hostname | Path | Description |
| --- | --- | --- |
| midnight | [./modules/android/hosts/midnight.nix](https://github.com/jaspine/d1/tree/master/nix/modules/android/hosts/midnight.nix) | WIP: My primary Android phone as a Robotnix declarative build, running GrapheneOS with custom platform keys. |
