---
name: nix-verify
description: Verify a change to this NixOS flake. Runs just check, builds the affected hosts (all of them if a shared module changed), diffs each against its running system and reports package, service and risky changes per host. Use after editing any .nix file, flake.lock or service config, and before telling the user a change is ready.
---

# nix-verify

Verify the working tree without deploying anything. Only use `just` recipes; never `sudo`, never deploy.

## 1. Work out the affected hosts

Look at `git status --short` and `git diff HEAD --stat` (plus any host the user named). Map paths using the table in CLAUDE.md:

- `flake.nix`, `flake.lock`, `utils/`, `modules/default.nix`, `modules/base/**`, `users/**` → **all hosts**
- `machines/aspire/`, `modules/{boot,containers,networking,services,storage}/**` → `aspire`
- `machines/wsl/`, `modules/claude-code/` → `wsl`
- Anything else, or a new module whose enabling host is unclear → **all hosts**

Untracked new files must be `git add`-ed first or the flake won't see them; do that and mention it.

## 2. Check and build

1. `just check`. Stop and report on failure (show the relevant error lines and the likely cause).
2. `just build <host>` for each affected host, or `just build-all` when all hosts are affected. On a build failure, stop and report.

## 3. Diff

Run `just diff <host>` for each affected host. For `aspire` this fetches the running closure over SSH; if SSH fails, say so and still report the build result.

The output has sections: Packages (nvd), Boot, Systemd units, Unit diff (for sshd/firewall/fail2ban/networking units), Sensitive /etc files, Users and groups.

## 4. Report

Per host, keep it short:

```
### <host>: built OK
Packages: <n added, n removed, notable version bumps (major versions first)>
Services: <units added/removed; changed units grouped, e.g. "12 podman-media-server-* (image config)"; omit units changed only by a package bump unless relevant>
Risky: <list, or "none">
```

Flag as **risky** (quote the relevant diff lines):

- sshd: `sshd_config` or `sshd.service` changes, port, auth methods, `PermitRootLogin`, authorised keys
- firewall: `firewall.service`/`nftables.service` script changes (opened/closed ports), fail2ban
- users and groups: added/removed users, group membership (especially `wheel`), shell, password file, sudoers
- boot: kernel or initrd change, kernel-params, bootloader, initrd SSH unlock (`modules/boot/remote-unlock`)
- networking: interfaces, DNS, `hosts`, networkd/resolved, `networking.*` changes
- anything that could lock the user out of `aspire` (SSH, network, boot, ZFS pool import); say so explicitly as it would need physical access

Finish with one line: ready to deploy (`just deploy-wsl` / `just deploy-server`, which the user runs) or what to fix first.
