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
  prometheus_node_exporter_port = 9100;
  cfg = config.modules.services.${service};
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
      prometheus_node_exporter_port
    ];

    # Containers
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
    virtualisation.oci-containers.containers."monitoring-prometheus" = {
      image = "docker.io/prom/prometheus:latest";
      volumes = [
        "${prometheus_ref_dir}:/etc/prometheus:rw"
        "monitoring-prometheus-data:/prometheus:rw"
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
    virtualisation.oci-containers.containers."monitoring-prometheus-node-exporter" = {
      image = "docker.io/prom/node-exporter:latest";
      volumes = [
        "/:/host:ro,rslave"
      ];
      ports = [
        "${toString prometheus_node_exporter_port}:9100/tcp"
      ];
      cmd = [ "--path.rootfs=/host" ];
      labels = {
        "io.containers.autoupdate" = "registry";
      };
      log-driver = "journald";
      extraOptions = [
        "--network=host"
      ];
    };
    systemd.services."podman-monitoring-prometheus-node-exporter" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
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
