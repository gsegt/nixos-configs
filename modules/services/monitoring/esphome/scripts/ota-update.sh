#!/usr/bin/env bash
# Build and push ESPHome firmware over the air to plugs already running ESPHome.
# Each plug is reached at the `address` set in its devices/plug-*.yaml.
#
# A plug cuts power to its load for a moment while it reboots, so plugs feeding
# critical loads ask for confirmation first (skip with -y).
#
# Usage: scripts/ota-update.sh [-y] [plug ...]   (default: every devices/plug-*.yaml)
set -euo pipefail

cd "$(dirname "$0")/.."

# Plugs whose reboot interrupts something you care about
confirm_plugs=(plug-desktop plug-server)

assume_yes=false
if [[ ${1:-} == -y ]]; then
  assume_yes=true
  shift
fi

if [[ ! -f secrets.yaml ]]; then
  echo "secrets.yaml missing: copy secrets.yaml.example and fill it in." >&2
  exit 1
fi

plugs=()
if [[ $# -gt 0 ]]; then
  for p in "$@"; do
    p="${p##*/}"
    plugs+=("${p%.yaml}")
  done
else
  # Least disruptive first, the server last
  for f in devices/plug-*.yaml; do
    f="${f##*/}"
    p="${f%.yaml}"
    [[ " ${confirm_plugs[*]} " == *" $p "* ]] || plugs+=("$p")
  done
  for p in "${confirm_plugs[@]}"; do [[ -f devices/$p.yaml ]] && plugs+=("$p"); done
fi

updated=()
skipped=()
failed=()
for plug in "${plugs[@]}"; do
  if ! $assume_yes && [[ " ${confirm_plugs[*]} " == *" $plug "* ]]; then
    read -rp "Updating $plug briefly cuts power to its load. Continue? [y/N] " answer
    if [[ $answer != [yY]* ]]; then
      skipped+=("$plug")
      continue
    fi
  fi
  echo "==> Updating $plug"
  if nix run nixpkgs#esphome -- run "devices/$plug.yaml" --device OTA --no-logs; then
    updated+=("$plug")
  else
    failed+=("$plug")
  fi
done

echo
echo "Updated: ${updated[*]:-none}"
echo "Skipped: ${skipped[*]:-none}"
echo "Failed:  ${failed[*]:-none}"
[[ ${#failed[@]} -eq 0 ]]
