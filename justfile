# Recurring commands for this flake, shared by humans and Claude Code.
# Run `just` to list them.

set shell := ["bash", "-euo", "pipefail", "-c"]
set positional-arguments := true

# SSH alias of the server (see users/gsegt/ssh), also its nixosConfigurations name.
server := "aspire"

_default:
    @just --list --unsorted

# Evaluate the flake and run its checks
check:
    nix flake check

# Build HOST's system closure into ./result-HOST
build HOST: (_assert-host HOST)
    nix build .#nixosConfigurations.{{ HOST }}.config.system.build.toplevel --out-link result-{{ HOST }}

# Build every host (needed whenever a shared module changes)
build-all:
    for host in $(just _hosts); do just build "$host"; done

# Compare HOST's running system with a fresh build (packages, units, sensitive config)
diff HOST: (build HOST)
    #!/usr/bin/env bash
    set -euo pipefail
    host="$1"
    new=$(readlink -f "result-$host")
    if [[ "$host" == "$(hostname)" ]]; then
        old=$(readlink -f /run/current-system)
    else
        echo "Fetching the running system of $host..." >&2
        old=$(ssh "$host" readlink -f /run/current-system)
        # Paths built locally are unsigned; gsegt is a trusted user (@wheel), so skipping the check is allowed.
        nix copy --no-check-sigs --from "ssh-ng://$host" "$old"
        nix-store --add-root "current-$host" --realise "$old" >/dev/null
    fi

    section() { printf '\n=== %s\n' "$1"; }

    section "Packages ($old -> $new)"
    nvd diff "$old" "$new"

    section "Boot"
    if [[ ! -e "$old/kernel" && ! -e "$new/kernel" ]]; then
        echo "no kernel in either closure (e.g. WSL)"
    else
        for f in kernel initrd; do
            o=$(readlink -f "$old/$f" || true) n=$(readlink -f "$new/$f" || true)
            [[ "$o" == "$n" ]] && echo "$f: unchanged" || echo "$f: $o -> $n"
        done
        diff -u --label old --label new "$old/kernel-params" "$new/kernel-params" && echo "kernel-params: unchanged" || true
    fi

    # Each unit is its own store path, so a different symlink target means the unit changed
    # (its settings or a package it references).
    section "Systemd units"
    units() { find "$1/etc/systemd/system/" -maxdepth 1 -type l -printf '%f\n' | sort; }
    comm -13 <(units "$old") <(units "$new") | sed 's/^/added:   /'
    comm -23 <(units "$old") <(units "$new") | sed 's/^/removed: /'
    changed=$(comm -12 <(units "$old") <(units "$new") | while read -r u; do
        [[ $(readlink -f "$old/etc/systemd/system/$u") == $(readlink -f "$new/etc/systemd/system/$u") ]] || echo "$u"
    done)
    [[ -n "$changed" ]] && sed 's/^/changed: /' <<<"$changed" || echo "no changed units"

    # Show the actual diff for units that guard access to the machine, including their start scripts.
    exec_paths() { grep -oE '^Exec[A-Za-z]*=[-@!+:]*/nix/store/[^ ]+' "$1" | sed -E 's/^[^=]*=[-@!+:]*//'; }
    for u in sshd.service sshd.socket firewall.service nftables.service fail2ban.service \
        systemd-networkd.service NetworkManager.service systemd-resolved.service; do
        grep -qxF "$u" <<<"$changed" || continue
        section "Unit diff: $u"
        o="$old/etc/systemd/system/$u" n="$new/etc/systemd/system/$u"
        diff -u --label "old/$u" --label "new/$u" "$o" "$n" || true
        paste <(exec_paths "$o") <(exec_paths "$n") | while read -r a b; do
            [[ -n "$a" && -n "$b" && "$a" != "$b" && -f "$a" && -f "$b" ]] && grep -Iq . "$b" || continue
            diff -u --label "old/$(basename "$a")" --label "new/$(basename "$b")" "$a" "$b" || true
        done
    done

    section "Sensitive /etc files"
    for f in ssh/sshd_config sudoers hosts nsswitch.conf systemd/network; do
        [[ -e "$old/etc/$f" || -e "$new/etc/$f" ]] || continue
        diff -ru --label "old/etc/$f" --label "new/etc/$f" "$old/etc/$f" "$new/etc/$f" 2>&1 && echo "etc/$f: unchanged" || true
    done

    section "Users and groups"
    users_json() { nix-store -qR "$1" | grep -m1 'users-groups.json$' || true; }
    uo=$(users_json "$old") un=$(users_json "$new")
    if [[ -z "$uo" || -z "$un" ]]; then
        echo "users-groups.json not found in a closure, compare users.users by hand"
    elif [[ "$uo" == "$un" ]]; then
        echo "unchanged"
    else
        diff -u --label old --label new <(jq -S . "$uo") <(jq -S . "$un") || true
    fi

# Format every Nix file (nixfmt-tree, pinned by flake.lock, same as CI)
fmt:
    nix fmt

# Update all flake inputs, or only the given ones
update *INPUTS:
    nix flake update "$@"

# Switch this WSL machine to the current config
deploy-wsl:
    nh os switch --ask --hostname wsl .

# Build locally and switch the server to the current config
deploy-server:
    nh os switch --ask --hostname {{ server }} --target-host {{ server }} --elevation-strategy passwordless .

# Read-only: last LINES journal lines of a server unit (globs allowed, e.g. 'podman-notes-*')
logs SVC LINES="200": (_assert-unit SVC)
    [[ "$2" =~ ^[0-9]+$ ]] || { echo "LINES must be a number" >&2; exit 1; }
    ssh {{ server }} -- journalctl --no-pager -o short-iso -n "$2" -u "'$1'"

# Read-only: systemctl status of a server unit (globs allowed)
status SVC: (_assert-unit SVC)
    ssh {{ server }} -- systemctl status --no-pager --lines=30 "'$1'"

# Names of all nixosConfigurations
_hosts:
    @nix eval --raw .#nixosConfigurations --apply 'c: toString (builtins.attrNames c)'

_assert-host HOST:
    #!/usr/bin/env bash
    set -euo pipefail
    hosts=$(just _hosts)
    [[ "$1" =~ ^[A-Za-z0-9_-]+$ && " $hosts " == *" $1 "* ]] || { echo "unknown host '$1', expected one of: $hosts" >&2; exit 1; }

# ssh re-parses its arguments in the remote shell, so only allow unit-name characters.
_assert-unit SVC:
    @[[ "$1" =~ ^[A-Za-z0-9@._:*-]+$ ]] || { echo "invalid unit name '$1'" >&2; exit 1; }
