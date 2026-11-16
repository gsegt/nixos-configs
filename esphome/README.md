# ESPHome power-monitoring plugs

GHome EP2-A plugs (ESP8266 + BL0937) running ESPHome. This is device firmware,
not NixOS config: nothing in the flake imports it.

- **Prometheus** scrapes their `/metrics` endpoint (`esphome` job in
  `modules/services/monitoring/prometheus/prometheus.yml`).
- **Home Assistant** (`modules/services/home-assistant`) talks to them over the
  encrypted native API (port 6053), one key per plug.

```
esphome/
├── devices/          one file per plug: name, IP, API key, calibration, relay mode
├── packages/         shared config included by every device
│   ├── common.yaml           board, Wi-Fi, OTA, API, LEDs, power sensors, /metrics
│   ├── relay-switchable.yaml relay toggled by the button and Home Assistant
│   ├── relay-locked.yaml     relay forced on, no button, hidden (plug-server)
│   └── secrets.yaml          symlink to ../secrets.yaml (ESPHome looks here)
├── scripts/
│   ├── build-firmware.sh     first flash: .bin.gz to upload through Tasmota
│   └── ota-update.sh         later updates over Wi-Fi
├── secrets.yaml.example
└── secrets.yaml      local, git-ignored: copy the example and fill it in
```

| Plug | IP | Relay |
| --- | --- | --- |
| plug-3d-printer | 192.168.1.246 | switchable |
| plug-tv | 192.168.1.247 | switchable |
| plug-server | 192.168.1.248 | locked on |
| plug-desktop | 192.168.1.249 | switchable |

IPs are DHCP reservations; keep `devices/*.yaml` and `prometheus.yml` in sync.

The API's `reboot_timeout` is disabled: by default a plug reboots after 15 min
without Home Assistant, which would cut power to its load (for plug-server, the
server running Home Assistant).

## Adding a plug

1. Copy a file in `devices/`, set `name`, `friendly_name`, `address`, the
   `api_key` secret name and the relay package.
2. Add `plug_<name>_api_key` to `secrets.yaml` (`head -c 32 /dev/urandom | base64`).
3. `scripts/build-firmware.sh plug-<name>`, then upload the `.bin.gz` through Tasmota.
4. Add the IP to the `esphome` job in `prometheus.yml`.
5. In Home Assistant: Settings → Devices & services → Add integration →
   ESPHome, enter the IP, then the plug's API key.

## Calibration

- `voltage_divider`: multiply by `230 / reading` (French mains, 230 V).
- `current_resistor`: multiply by `reading / real watts`, using a known resistive
  load (kettle, heater).

Updating a plug reboots it, which briefly cuts power to its load.
