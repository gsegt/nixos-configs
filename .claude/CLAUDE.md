# CLAUDE.md

NixOS flake configuration for two hosts: `wsl` (nixos-unstable) and `aspire` (home server, nixos-26.05-small). See README.md for architecture and install steps.

## Layout

- `flake.nix`: inputs and `nixosConfigurations.{wsl,aspire}`, each built with `mkHost` (picks the host's nixpkgs channel and matching home-manager; sops-nix and other modules are shared). The server uses `nixpkgs-server`/`home-manager-server` pinned to the stable release. All flake inputs reach modules as the `inputs` argument; set the platform with `nixpkgs.hostPlatform` in the machine config.
- `machines/<host>/`: per-host config, enables modules through `modules.<category>.<name>` options.
- `modules/<category>/<name>/default.nix`: custom modules. Each one declares `options.modules.<category>.<name>` with `lib.mkEnableOption` and wraps its config in `lib.mkIf cfg.enable`. Submodules are auto-imported by `utils/importSubmodules.nix` (any subfolder with a `default.nix`), so no manual import list needs updating.
- `modules/services/<name>/`: mostly docker-compose services (compose file + committed `.env` holding non-secret config) wired in through Nix.
- `users/<user>/`: home-manager config, same auto-import pattern.
- `secrets/default.yaml`: sops-encrypted (age). Never decrypt it or try to read the age key (`/etc/secrets/sops/age/keys.txt`). To add a secret, ask the user to run `sops secrets/default.yaml`; keep keys in alphabetical order.
- `modules/services/drive/compose`: git submodule (upstream opencloud-compose), don't edit it.

## Workflow

- Flakes only see git-tracked files: `git add` new files before evaluating or building.
- Format: `nixfmt <file>` (CI runs `nix run nixpkgs#nixfmt-tree -- --ci`). A hook formats `.nix` files automatically after edits.
- Validate: `nix flake check`, then `nixos-rebuild build --flake .#<host>` for the host you touched. On WSL you can build `aspire` too, so check both when you change shared modules.
- Don't run `nixos-rebuild switch`/`boot` or `nix flake update` unless asked; the user applies changes themselves.
- Commits follow Conventional Commits (commitlint in CI): `type(scope): subject`, scope is usually the module name, e.g. `feat(monitoring): ...`, `fix(media-server): ...`. Flake input bumps use `feat(flake)!: update to latest version`.
- Spelling: British English.
