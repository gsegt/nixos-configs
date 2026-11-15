---
name: nix-update
description: Update the flake inputs (all, or the named ones), verify every host and summarise version bumps and breaking changes worth checking.
disable-model-invocation: true
argument-hint: "[input ...]"
---

# nix-update

The user invoked this explicitly, which authorises `just update` for this run only. Never deploy, never commit unless asked.

1. Note the current state: `git status --short` (warn if `flake.lock` already has uncommitted changes) and `nix flake metadata` for the current revisions.
2. Run `just update $ARGUMENTS` (no arguments updates every input).
3. Show which inputs moved: `git diff flake.lock`. For each changed input give old → new revision and date (`lastModified`). If nothing changed, say so and stop.
4. Run the **nix-verify** skill. `flake.lock` is shared, so this builds and diffs **all hosts**.
5. Summarise per host:
   - **Version bumps** from the nvd output: major and minor bumps first (kernel, systemd, openssh, podman, nix, home-manager, and anything the services depend on), then a count of the rest.
   - **Breaking changes worth checking**:
     - evaluation warnings or deprecation notices printed by `just check` / the builds (renamed or removed options)
     - for `nixpkgs-server` (26.05-small), changes across a release boundary: point to the NixOS release notes
     - for `nixpkgs` (unstable) and `home-manager`: major version bumps of packages in use
     - `system.stateVersion` / `home.stateVersion` are `25.05`: never change them, but flag release notes that mention stateVersion-gated behaviour
     - the risky items reported by nix-verify (sshd, firewall, users, boot, networking)
6. End with: the suggested commit message `feat(flake)!: update to latest version` and that the user deploys with `just deploy-wsl` / `just deploy-server`. If anything failed, show the error and suggest either a fix or reverting with `git checkout flake.lock`.
