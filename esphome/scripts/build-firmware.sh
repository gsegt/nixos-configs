#!/usr/bin/env bash
# Build ESPHome firmware for the plugs and copy it, gzipped, to OUT_DIR, ready
# to upload through Tasmota's "Firmware Upgrade" page (first flash only; later
# updates go through ota-update.sh).
#
# Usage: scripts/build-firmware.sh [plug ...]   (default: every devices/plug-*.yaml)
#        OUT_DIR=/some/dir scripts/build-firmware.sh plug-tv
set -euo pipefail

cd "$(dirname "$0")/.."

out_dir="${OUT_DIR:-/mnt/c/Users/$USER/Downloads}"

if [[ ! -f secrets.yaml ]]; then
  echo "secrets.yaml missing: copy secrets.yaml.example and fill it in." >&2
  exit 1
fi
mkdir -p "$out_dir"

plugs=()
if [[ $# -gt 0 ]]; then
  for p in "$@"; do
    p="${p##*/}"
    plugs+=("${p%.yaml}")
  done
else
  for f in devices/plug-*.yaml; do
    f="${f##*/}"
    plugs+=("${f%.yaml}")
  done
fi

for plug in "${plugs[@]}"; do
  echo "==> Building $plug"
  nix run nixpkgs#esphome -- compile "devices/$plug.yaml"
  gzip -c "devices/.esphome/build/$plug/.pioenvs/$plug/firmware.bin" >"$out_dir/$plug.bin.gz"
done

echo
echo "Firmware written to $out_dir:"
for plug in "${plugs[@]}"; do ls -l "$out_dir/$plug.bin.gz"; done
