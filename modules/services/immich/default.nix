{
  pkgs,
  lib,
  config,
  ...
}:

let
  service = "immich";
  server_port = 2283;
  server_subdomain = service;
  server_uri = "${server_subdomain}.${config.modules.services.reverse-proxy.domain}";
  server_uid = 0;
  server_gid = 0;
  server_volume_dir = "${cfg.volumeDir}/server";
  server_data_dir = "${server_volume_dir}/data";
  postgres_uid = 999;
  postgres_gid = 999;
  postgres_volume_dir = "${cfg.volumeDir}/postgres";
  postgres_data_dir = "${postgres_volume_dir}/data";
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
      "immich/server/env" = { };
      "immich/postgres/env" = { };
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.volumeDir} 0755 ${config.modules.base.userName} ${config.modules.base.groupName} - -"
      "d ${server_volume_dir} 0755 ${toString server_uid} ${toString server_gid} - -"
      "d ${server_data_dir} 0755 ${toString server_uid} ${toString server_gid} - -"
      "d ${postgres_volume_dir} 0755 ${toString postgres_uid} ${toString postgres_gid} - -"
      "d ${postgres_data_dir} 0755 ${toString postgres_uid} ${toString postgres_gid} - -"
    ];

    services.${config.modules.services.reverse-proxy.service} = {
      virtualHosts."${server_uri}".extraConfig = ''
        reverse_proxy localhost:${toString server_port}
      '';
    };

    modules.services.dyndns-ovh.subdomains = [ server_subdomain ];

    # Containers
    virtualisation.oci-containers.containers."immich-machine-learning" = {
      image = "ghcr.io/immich-app/immich-machine-learning:release-openvino";
      volumes = [
        "/dev/bus/usb:/dev/bus/usb:rw"
        "model-cache:/cache:rw"
      ];
      labels = {
        "io.containers.autoupdate" = "registry";
      };
      log-driver = "journald";
      extraOptions = [
        "--device=/dev/dri:/dev/dri:rwm"
        "--network-alias=immich-machine-learning"
        "--network=immich"
      ];
    };
    systemd.services."podman-immich-machine-learning" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "podman-network-immich.service"
        "podman-volume-model-cache.service"
      ];
      requires = [
        "podman-network-immich.service"
        "podman-volume-model-cache.service"
      ];
      partOf = [
        "podman-compose-immich-root.target"
      ];
      wantedBy = [
        "podman-compose-immich-root.target"
      ];
    };
    virtualisation.oci-containers.containers."immich-postgres" = {
      image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23";
      environment = {
        "POSTGRES_DB" = "immich";
        "POSTGRES_INITDB_ARGS" = "--data-checksums";
        "POSTGRES_USER" = "postgres";
      };
      environmentFiles = [
        config.sops.secrets."immich/postgres/env".path
      ];
      volumes = [
        "${postgres_data_dir}:/var/lib/postgresql/data:rw"
      ];
      labels = {
        "compose2nix.settings.sops.secrets" = "immich/postgres/env";
      };
      log-driver = "journald";
      extraOptions = [
        "--network-alias=database"
        "--network=immich"
        "--shm-size=134217728"
      ];
    };
    systemd.services."podman-immich-postgres" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "podman-network-immich.service"
      ];
      requires = [
        "podman-network-immich.service"
      ];
      partOf = [
        "podman-compose-immich-root.target"
      ];
      wantedBy = [
        "podman-compose-immich-root.target"
      ];
    };
    virtualisation.oci-containers.containers."immich-redis" = {
      image = "docker.io/valkey/valkey:9@sha256:4963247afc4cd33c7d3b2d2816b9f7f8eeebab148d29056c2ca4d7cbc966f2d9";
      log-driver = "journald";
      extraOptions = [
        "--health-cmd=redis-cli ping || exit 1"
        "--network-alias=redis"
        "--network=immich"
      ];
    };
    systemd.services."podman-immich-redis" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "podman-network-immich.service"
      ];
      requires = [
        "podman-network-immich.service"
      ];
      partOf = [
        "podman-compose-immich-root.target"
      ];
      wantedBy = [
        "podman-compose-immich-root.target"
      ];
    };
    virtualisation.oci-containers.containers."immich-server" = {
      image = "ghcr.io/immich-app/immich-server:release";
      environment = {
        "DB_DATABASE_NAME" = "immich";
        "DB_USERNAME" = "postgres";
        "TZ" = config.modules.base.timeZone;
      };
      environmentFiles = [
        config.sops.secrets."immich/server/env".path
      ];
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${server_data_dir}:/data:rw"
      ];
      ports = [
        "${toString server_port}:2283/tcp"
      ];
      labels = {
        "compose2nix.settings.sops.secrets" = "immich/server/env";
        "io.containers.autoupdate" = "registry";
      };
      dependsOn = [
        "immich-postgres"
        "immich-redis"
      ];
      log-driver = "journald";
      extraOptions = [
        "--device=/dev/dri:/dev/dri:rwm"
        "--network-alias=immich-server"
        "--network=immich"
      ];
    };
    systemd.services."podman-immich-server" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "podman-network-immich.service"
      ];
      requires = [
        "podman-network-immich.service"
      ];
      partOf = [
        "podman-compose-immich-root.target"
      ];
      wantedBy = [
        "podman-compose-immich-root.target"
      ];
    };

    # Networks
    systemd.services."podman-network-immich" = {
      path = [ pkgs.podman ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "podman network rm -f immich";
      };
      script = ''
        podman network inspect immich || podman network create immich
      '';
      partOf = [ "podman-compose-immich-root.target" ];
      wantedBy = [ "podman-compose-immich-root.target" ];
    };

    # Volumes
    systemd.services."podman-volume-model-cache" = {
      path = [ pkgs.podman ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        podman volume inspect model-cache || podman volume create model-cache
      '';
      partOf = [ "podman-compose-immich-root.target" ];
      wantedBy = [ "podman-compose-immich-root.target" ];
    };

    # Root service
    # When started, this will automatically create all resources and start
    # the containers. When stopped, this will teardown all resources.
    systemd.targets."podman-compose-immich-root" = {
      unitConfig = {
        Description = "Root target generated by compose2nix.";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
