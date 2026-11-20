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
  alertmanager_ref_dir = "/etc/nixos/modules/services/monitoring/alertmanager";
  alertmanager_port = 9093;
  blackbox_ref_dir = "/etc/nixos/modules/services/monitoring/blackbox";
  exporters = config.services.prometheus.exporters;
  cfg = config.modules.services.${service};

  # Probe every site the reverse proxy serves, plus the services that add
  # their own targets; read by Prometheus file_sd.
  blackboxTargets = pkgs.writeText "blackbox-targets.json" (
    builtins.toJSON [
      {
        targets =
          map (host: "https://${host}") (
            lib.optionals config.services.caddy.enable (builtins.attrNames config.services.caddy.virtualHosts)
          )
          ++ cfg.blackboxTargets;
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

    blackboxTargets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra URLs to probe, for services not behind the reverse proxy.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        # Alertmanager reuses the msmtp SMTP password
        assertion = config.modules.services.msmtp.enable;
        message = "modules.services.monitoring needs modules.services.msmtp for alert emails.";
      }
    ];

    sops.secrets =
      let
        # Alertmanager runs as nobody inside the container (same uid on the host)
        alertmanagerSecret = {
          owner = "nobody";
          restartUnits = [ "podman-monitoring-alertmanager.service" ];
        };
      in
      {
        "monitoring/alertmanager/healthcheck_url" = alertmanagerSecret;
        "monitoring/alertmanager/ntfy_token" = alertmanagerSecret;
        "monitoring/grafana/env" = { };
      };

    networking.firewall.allowedTCPPorts = [
      alertmanager_port
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
      restartTriggers = [ ./blackbox/blackbox.yml ];
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
      cmd = [
        "--config.file=/etc/prometheus/prometheus.yml"
        # Links in alert emails point here instead of the container id
        "--web.external-url=http://${config.modules.base.ipAddress}:${toString prometheus_port}"
      ];
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
      # Reload config and rules on switch (they are bind-mounted, not copied)
      restartTriggers = [
        ./prometheus/prometheus.yml
        ./prometheus/alerts.yml
      ];
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

    virtualisation.oci-containers.containers."monitoring-alertmanager" = {
      image = "docker.io/prom/alertmanager:latest";
      volumes = [
        "${alertmanager_ref_dir}/alertmanager.yml:/etc/alertmanager/alertmanager.yml:ro"
        "monitoring-alertmanager-data:/alertmanager:rw"
        "${config.sops.secrets."msmtp_default_password".path}:/etc/alertmanager/secrets/smtp_password:ro"
        "${
          config.sops.secrets."monitoring/alertmanager/ntfy_token".path
        }:/etc/alertmanager/secrets/ntfy_token:ro"
        "${
          config.sops.secrets."monitoring/alertmanager/healthcheck_url".path
        }:/etc/alertmanager/secrets/healthcheck_url:ro"
      ];
      ports = [
        "${toString alertmanager_port}:9093/tcp"
      ];
      cmd = [
        "--config.file=/etc/alertmanager/alertmanager.yml"
        "--storage.path=/alertmanager"
        "--web.external-url=http://${config.modules.base.ipAddress}:${toString alertmanager_port}"
      ];
      labels = {
        "io.containers.autoupdate" = "registry";
      };
      log-driver = "journald";
      extraOptions = [
        "--network-alias=alertmanager"
        "--network=monitoring"
      ];
    };
    systemd.services."podman-monitoring-alertmanager" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      restartTriggers = [ ./alertmanager/alertmanager.yml ];
      after = [
        "podman-network-monitoring.service"
        "podman-volume-monitoring-alertmanager-data.service"
      ];
      requires = [
        "podman-network-monitoring.service"
        "podman-volume-monitoring-alertmanager-data.service"
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
    systemd.services."podman-volume-monitoring-alertmanager-data" = {
      path = [ pkgs.podman ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        podman volume inspect monitoring-alertmanager-data || podman volume create monitoring-alertmanager-data
      '';
      partOf = [ "podman-compose-monitoring-root.target" ];
      wantedBy = [ "podman-compose-monitoring-root.target" ];
    };
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
