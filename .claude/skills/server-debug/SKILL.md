---
name: server-debug
description: Diagnose a failing or misbehaving service on the aspire server using only the read-only just logs / just status recipes, then propose a fix in this repo's config. Use when the user reports a server service being down, erroring, restarting or unreachable.
argument-hint: "[service or symptom]"
---

# server-debug

**Read-only on the server.** The only commands that touch `aspire` are `just status <unit>` and `just logs <unit> [lines]`. No raw `ssh`, no `sudo`, no restarts, no edits on the server. The fix goes into this repo and the user deploys it.

## 1. Find the units

Map the service to its module and units:

- Container services: `modules/services/<name>/default.nix` defines `virtualisation.oci-containers.containers."<name>-<container>"`, giving units `podman-<name>-<container>.service`, plus `podman-network-<name>.service`, sometimes `podman-volume-*`, all under `podman-compose-<name>-root.target`.
- Native services: read the module for the systemd unit (e.g. `caddy`, `fail2ban`, `sshd`, `zfs-*`, `dyndns-ovh`, `msmtp`).
- Globs work: `just status 'podman-notes-*'`.

## 2. Gather evidence

1. `just status <unit-or-glob>`: state, exit code, restart count, recent lines.
2. `just logs <unit> 200`: increase the line count only if needed. Also check the units it depends on (network/volume units, the database container, `sops-nix`, `zfs-load-keys`, `zfs-import-*`) when the error points there.
3. Stop once you have the root cause; don't dump whole logs into the reply.

## 3. Diagnose

Relate the error to the config: wrong image tag or env var, missing sops secret (`sops.secrets`, `environmentFiles`), volume path or ownership (`systemd.tmpfiles.rules`, `volumeDir` under `/media/external/data-vault/services`), port clash, reverse-proxy vhost, ordering (`after`/`requires`), ZFS pool not imported, an upstream image change after `io.containers.autoupdate`.

If the cause is outside the config (disk full, hardware, an upstream bug, a secret value), say so and tell the user what to check or run themselves.

## 4. Propose and verify a fix

- Explain the root cause in a few lines, quoting the decisive log lines.
- Propose the config change and make it if the user agrees (or if they asked for a fix). If it needs a new secret, ask the user to add it with `sops secrets/default.yaml`.
- Run the **nix-verify** skill for `aspire` and report.
- Tell the user to deploy with `just deploy-server`, and which `just status` / `just logs` to run afterwards to confirm.
