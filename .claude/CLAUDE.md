# CLAUDE.md

NixOS flake for two hosts, both built from this WSL machine. See README.md for architecture and install steps.

| Host | Role | nixpkgs |
|---|---|---|
| `wsl` | this machine (NixOS-WSL), where you work | `nixpkgs` (unstable) |
| `aspire` | home server, reached over SSH as `aspire` | `nixpkgs-server` (26.05-small) |

## What is shared

`modules/` is imported by both hosts and each host turns modules on with `modules.<category>.<name>.enable`.

- **Both hosts**: `flake.nix`, `flake.lock`, `utils/`, `modules/default.nix`, `modules/base/**` (nix, sops, home-manager, editor, zram, …), `users/gsegt/**`.
- **`aspire` only**: `machines/aspire/`, `modules/{boot,containers,networking,services,storage}/**`.
- **`wsl` only**: `machines/wsl/`, `modules/claude-code/`.
- **Neither**: `esphome/` is firmware for the smart plugs, not Nix (see its README); it needs no build.

**A change to anything shared means `just build-all`.** When unsure, build all.

## Verify

All recurring commands live in the `justfile` (`just` lists them):

1. `just check` (`nix flake check`)
2. `just build <host>` for the host(s) you touched, or `just build-all`
3. `just diff <host>` to compare against what is running (fetches the server's closure over SSH)

The `nix-verify` skill runs this sequence and reports per host. Flakes only see git-tracked files: `git add` new files first. `just fmt` formats everything; a hook formats `.nix` files after each edit.

## Hard rules

- **Never deploy.** Don't run `just deploy-*`, `nh os switch`, `nixos-rebuild switch/boot/test`, or `just update` unless asked; the user deploys.
- **Never use `sudo`**, and never change the server directly: on `aspire`, only `just logs` / `just status` (read-only). Fixes go into this repo.
- **Never touch secrets.** `secrets/default.yaml` is sops-encrypted: never decrypt it or read the age key (`/etc/secrets/sops/age/keys.txt`), `/run/secrets`, `~/.ssh`, or the git-ignored `esphome/secrets.yaml` (also reachable through the `devices/secrets.yaml` symlink). To add a secret, ask the user to run `sops secrets/default.yaml` (keys in alphabetical order).

## Conventions

- Module pattern: `modules/<category>/<name>/default.nix` declares `options.modules.<category>.<name>` with `lib.mkEnableOption` and wraps config in `lib.mkIf cfg.enable`. Subfolders with a `default.nix` are auto-imported (`utils/importSubmodules.nix`); `users/<user>/` works the same way with home-manager.
- `modules/services/<name>/`: compose2nix-style `virtualisation.oci-containers` (podman, journald logging). Units are named `podman-<service>-<container>`, grouped under `podman-compose-<service>-root.target`. Secrets come from sops `environmentFiles`.
- Service folders: tmpfiles only creates `volumeDir` (owned by the user). Each container unit creates the folders it bind-mounts under `volumeDir` in its own `preStart`, parents first, owned by the `<container>_uid`/`_gid` it runs as. Folders are only created when missing, so containers sharing a folder can all list it:
  ```nix
  preStart = ''
    for d in ${joplin_volume_dir} ${joplin_data_dir}; do
      [ -d "$d" ] || install -d -m 0755 -o ${toString joplin_uid} -g ${toString joplin_gid} "$d"
    done
  '';
  ```
  Don't add container folders to tmpfiles: it refuses paths owned by another user under `volumeDir` ("unsafe path transition").
- `modules/services/drive/compose` is a git submodule (upstream opencloud-compose): don't edit it.
- Commits: Conventional Commits (commitlint in CI), `type(scope): subject` with the module as scope, e.g. `fix(media-server): ...`. Input bumps: `feat(flake)!: update to latest version`.
- Spelling: British English.
