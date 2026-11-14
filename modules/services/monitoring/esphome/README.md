# ESPHome power-monitoring plugs

GHome EP2-A plugs (ESP8266 + BL0937) running ESPHome, scraped by Prometheus
through their `/metrics` endpoint (`esphome` job in `../prometheus/prometheus.yml`).

```
esphome/
├── devices/          one file per plug: name, IP, calibration, relay mode
├── packages/         shared config included by every device
│   ├── common.yaml           board, Wi-Fi, OTA, LEDs, power sensors, /metrics
│   ├── relay-switchable.yaml relay toggled by the button
│   ├── relay-locked.yaml     relay forced on, no button (plug-server)
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

## Adding a plug

1. Copy a file in `devices/`, set `name`, `friendly_name`, `address` and the relay package.
2. `scripts/build-firmware.sh plug-<name>`, then upload the `.bin.gz` through Tasmota.
3. Add the IP to the `esphome` job in `prometheus.yml`.

## Calibration

- `voltage_divider`: multiply by `230 / reading` (French mains, 230 V).
- `current_resistor`: multiply by `reading / real watts`, using a known resistive
  load (kettle, heater).

Updating a plug reboots it, which briefly cuts power to its load.
