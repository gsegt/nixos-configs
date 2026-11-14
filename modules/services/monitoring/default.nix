{
  pkgs,
  lib,
  config,
  ...
}:

let
  service = "monitoring";
  grafana_ref_dir = "/etc/nixos/modules/services/monitoring/grafana";
  grafana_port = 3000;
  prometheus_ref_dir = "/etc/nixos/modules/services/monitoring/prometheus";
  prometheus_port = 9090;
  blackbox_ref_dir = "/etc/nixos/modules/services/monitoring/blackbox";
  exporters = config.services.prometheus.exporters;
  cfg = config.modules.services.${service};

  # Probe every site the reverse proxy serves; read by Prometheus file_sd.
  blackboxTargets = pkgs.writeText "blackbox-targets.json" (
    builtins.toJSON [
      {
        targets = map (host: "https://${host}") (
          lib.optionals config.services.caddy.enable (builtins.attrNames config.services.caddy.virtualHosts)
        );
      }
    ]
  );
in
{
  options.modules.services.${service} = {
    enable = lib.mkEnableOption "Whether to enable custom ${service} settings.";

    volumeDir = lib.mkOption {
      type = lib.types.path;
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      "monitoring/grafana/env" = { };
    };

    networking.firewall.allowedTCPPorts = [
      grafana_port
      prometheus_port
    ];

    # Host exporters are reachable from Prometheus (via host.containers.internal)
    # but not from the LAN.
    networking.firewall.interfaces.${config.modules.containers.podmanInterfaces}.allowedTCPPorts = [
      exporters.node.port
      exporters.smartctl.port
    ]
    ++ lib.optional exporters.zfs-siebenmann.enable exporters.zfs-siebenmann.port;

    # Host agents run natively: they are tied to this machine's hardware and
    # kernel. On another OS, install the same exporters from its packages
    # (see the note in docker-compose.yml); metric names stay the same.
    services.prometheus.exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
      };
      # Discovers every disk with `smartctl --scan`
      smartctl.enable = true;
      # Pool health, scrub results and per-disk read/write/checksum errors
      zfs-siebenmann = lib.mkIf config.modules.storage.zfs.enable {
        enable = true;
        depth = 2;
      };
    };

    # Containers
    virtualisation.oci-containers.containers."monitoring-blackbox-exporter" = {
      image = "docker.io/prom/blackbox-exporter:latest";
      volumes = [
        "${blackbox_ref_dir}/blackbox.yml:/etc/blackbox_exporter/config.yml:ro"
      ];
      cmd = [ "--config.file=/etc/blackbox_exporter/config.yml" ];
      labels = {
        "io.containers.autoupdate" = "registry";
      };
      log-driver = "journald";
      extraOptions = [
        "--network-alias=blackbox-exporter"
        "--network=monitoring"
      ];
    };
    systemd.services."podman-monitoring-blackbox-exporter" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "podman-network-monitoring.service"
      ];
      requires = [
        "podman-network-monitoring.service"
      ];
      partOf = [
        "podman-compose-monitoring-root.target"
      ];
      wantedBy = [
        "podman-compose-monitoring-root.target"
      ];
    };
    virtualisation.oci-containers.containers."monitoring-grafana" = {
      image = "docker.io/grafana/grafana:latest";
      environment = {
        "GF_SECURITY_ADMIN_USER" = "admin";
      };
      environmentFiles = [
        config.sops.secrets."monitoring/grafana/env".path
      ];
      volumes = [
        "${grafana_ref_dir}/dashboard-provider.yml:/etc/grafana/provisioning/dashboards/provider.yml:ro"
        "${grafana_ref_dir}/dashboards:/var/lib/grafana/dashboards:ro"
        "${grafana_ref_dir}/datasource.yml:/etc/grafana/provisioning/datasources/datasource.yml:ro"
      ];
      ports = [
        "${toString grafana_port}:3000/tcp"
      ];
      labels = {
        "compose2nix.settings.sops.secrets" = "monitoring/grafana/env";
        "io.containers.autoupdate" = "registry";
      };
      log-driver = "journald";
      extraOptions = [
        "--network-alias=grafana"
        "--network=monitoring"
      ];
    };
    systemd.services."podman-monitoring-grafana" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "podman-network-monitoring.service"
      ];
      requires = [
        "podman-network-monitoring.service"
      ];
      partOf = [
        "podman-compose-monitoring-root.target"
      ];
      wantedBy = [
        "podman-compose-monitoring-root.target"
      ];
    };
    virtualisation.oci-containers.containers."monitoring-podman-exporter" = {
      # v1.x supports Podman 5; v2 (`latest`) requires Podman 6
      image = "quay.io/navidys/prometheus-podman-exporter:v1.21.2";
      environment = {
        "CONTAINER_HOST" = "unix:///run/podman/podman.sock";
      };
      volumes = [
        "/run/podman/podman.sock:/run/podman/podman.sock:ro"
      ];
      cmd = [ "--collector.enhance-metrics" ];
      labels = {
        "io.containers.autoupdate" = "registry";
      };
      user = "root";
      log-driver = "journald";
      extraOptions = [
        "--network-alias=podman-exporter"
        "--network=monitoring"
      ];
    };
    systemd.services."podman-monitoring-podman-exporter" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "podman-network-monitoring.service"
      ];
      requires = [
        "podman-network-monitoring.service"
      ];
      partOf = [
        "podman-compose-monitoring-root.target"
      ];
      wantedBy = [
        "podman-compose-monitoring-root.target"
      ];
    };
    virtualisation.oci-containers.containers."monitoring-prometheus" = {
      image = "docker.io/prom/prometheus:latest";
      volumes = [
        "${prometheus_ref_dir}:/etc/prometheus:rw"
        "monitoring-prometheus-data:/prometheus:rw"
        "${blackboxTargets}:/etc/prometheus-file-sd/blackbox.json:ro"
      ];
      ports = [
        "${toString prometheus_port}:9090/tcp"
      ];
      cmd = [ "--config.file=/etc/prometheus/prometheus.yml" ];
      labels = {
        "io.containers.autoupdate" = "registry";
      };
      log-driver = "journald";
      extraOptions = [
        "--network-alias=prometheus"
        "--network=monitoring"
      ];
    };
    systemd.services."podman-monitoring-prometheus" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "podman-network-monitoring.service"
        "podman-volume-monitoring-prometheus-data.service"
      ];
      requires = [
        "podman-network-monitoring.service"
        "podman-volume-monitoring-prometheus-data.service"
      ];
      partOf = [
        "podman-compose-monitoring-root.target"
      ];
      wantedBy = [
        "podman-compose-monitoring-root.target"
      ];
    };

    # Networks
    systemd.services."podman-network-monitoring" = {
      path = [ pkgs.podman ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "podman network rm -f monitoring";
      };
      script = ''
        podman network inspect monitoring || podman network create monitoring
      '';
      partOf = [ "podman-compose-monitoring-root.target" ];
      wantedBy = [ "podman-compose-monitoring-root.target" ];
    };

    # Volumes
    systemd.services."podman-volume-monitoring-prometheus-data" = {
      path = [ pkgs.podman ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        podman volume inspect monitoring-prometheus-data || podman volume create monitoring-prometheus-data
      '';
      partOf = [ "podman-compose-monitoring-root.target" ];
      wantedBy = [ "podman-compose-monitoring-root.target" ];
    };

    # Root service
    # When started, this will automatically create all resources and start
    # the containers. When stopped, this will teardown all resources.
    systemd.targets."podman-compose-monitoring-root" = {
      unitConfig = {
        Description = "Root target generated by compose2nix.";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
