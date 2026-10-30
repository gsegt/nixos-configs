{
  pkgs,
  lib,
  config,
  ...
}:

let
  service = "photos";
  subdomain = service;
  uri = "${subdomain}.${config.modules.services.reverse-proxy.domain}";
  immich_server_volume_dir = "${cfg.volumeDir}/immich-server";
  immich_server_data_dir = "${immich_server_volume_dir}/data";
  immich_server_uid = 0;
  immich_server_gid = 0;
  immich_server_port = 2283;
  postgres_volume_dir = "${cfg.volumeDir}/postgres";
  postgres_data_dir = "${postgres_volume_dir}/data";
  postgres_uid = 999;
  postgres_gid = 999;
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
      "photos/immich-server/env" = { };
      "photos/postgres/env" = { };
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.volumeDir} 0755 ${config.modules.base.userName} ${config.modules.base.groupName} - -"
      "d ${immich_server_volume_dir} 0755 ${toString immich_server_uid} ${toString immich_server_gid} - -"
      "d ${immich_server_data_dir} 0755 ${toString immich_server_uid} ${toString immich_server_gid} - -"
      "d ${postgres_volume_dir} 0755 ${toString postgres_uid} ${toString postgres_gid} - -"
      "d ${postgres_data_dir} 0755 ${toString postgres_uid} ${toString postgres_gid} - -"
    ];

    services.${config.modules.services.reverse-proxy.service} = {
      virtualHosts."${uri}".extraConfig = ''
        reverse_proxy localhost:${toString immich_server_port}
      '';
    };

    modules.services.dyndns-ovh.subdomains = [ subdomain ];

    # Containers
    virtualisation.oci-containers.containers."photos-immich-machine-learning" = {
      image = "ghcr.io/immich-app/immich-machine-learning:release-openvino";
      volumes = [
        "/dev/bus/usb:/dev/bus/usb:rw"
        "photos-immich-machine-learning-model-cache:/cache:rw"
      ];
      labels = {
        "io.containers.autoupdate" = "registry";
      };
      log-driver = "journald";
      extraOptions = [
        "--device=/dev/dri:/dev/dri:rwm"
        "--network-alias=immich-machine-learning"
        "--network=photos"
      ];
    };
    systemd.services."podman-photos-immich-machine-learning" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "podman-network-photos.service"
        "podman-volume-photos-immich-machine-learning-model-cache.service"
      ];
      requires = [
        "podman-network-photos.service"
        "podman-volume-photos-immich-machine-learning-model-cache.service"
      ];
      partOf = [
        "podman-compose-photos-root.target"
      ];
      wantedBy = [
        "podman-compose-photos-root.target"
      ];
    };
    virtualisation.oci-containers.containers."photos-server" = {
      image = "ghcr.io/immich-app/immich-server:release";
      environment = {
        "DB_DATABASE_NAME" = "immich";
        "DB_USERNAME" = "postgres";
        "TZ" = config.modules.base.timeZone;
      };
      environmentFiles = [
        config.sops.secrets."photos/immich-server/env".path
      ];
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${immich_server_data_dir}:/data:rw"
      ];
      ports = [
        "${toString immich_server_port}:2283/tcp"
      ];
      labels = {
        "compose2nix.settings.sops.secrets" = "photos/immich-server/env";
        "io.containers.autoupdate" = "registry";
      };
      dependsOn = [
        "photos-postgres"
        "photos-redis"
      ];
      log-driver = "journald";
      extraOptions = [
        "--device=/dev/dri:/dev/dri:rwm"
        "--network-alias=immich-server"
        "--network=photos"
      ];
    };
    systemd.services."podman-photos-immich-server" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "podman-network-photos.service"
      ];
      requires = [
        "podman-network-photos.service"
      ];
      partOf = [
        "podman-compose-photos-root.target"
      ];
      wantedBy = [
        "podman-compose-photos-root.target"
      ];
    };
    virtualisation.oci-containers.containers."photos-postgres" = {
      image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23";
      environment = {
        "POSTGRES_DB" = "immich";
        "POSTGRES_INITDB_ARGS" = "--data-checksums";
        "POSTGRES_USER" = "postgres";
      };
      environmentFiles = [
        config.sops.secrets."photos/postgres/env".path
      ];
      volumes = [
        "${postgres_data_dir}:/var/lib/postgresql/data:rw"
      ];
      labels = {
        "compose2nix.settings.sops.secrets" = "photos/postgres/env";
      };
      log-driver = "journald";
      extraOptions = [
        "--network-alias=database"
        "--network=photos"
        "--shm-size=134217728"
      ];
    };
    systemd.services."podman-photos-postgres" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "podman-network-photos.service"
      ];
      requires = [
        "podman-network-photos.service"
      ];
      partOf = [
        "podman-compose-photos-root.target"
      ];
      wantedBy = [
        "podman-compose-photos-root.target"
      ];
    };
    virtualisation.oci-containers.containers."photos-redis" = {
      image = "docker.io/valkey/valkey:9@sha256:c123e3715db63d06d4ad6964884037aa0d5d4d703939b9929954112889708e1d";
      log-driver = "journald";
      extraOptions = [
        "--health-cmd=redis-cli ping || exit 1"
        "--network-alias=redis"
        "--network=photos"
      ];
    };
    systemd.services."podman-photos-redis" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "podman-network-photos.service"
      ];
      requires = [
        "podman-network-photos.service"
      ];
      partOf = [
        "podman-compose-photos-root.target"
      ];
      wantedBy = [
        "podman-compose-photos-root.target"
      ];
    };

    # Networks
    systemd.services."podman-network-photos" = {
      path = [ pkgs.podman ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "podman network rm -f photos";
      };
      script = ''
        podman network inspect photos || podman network create photos
      '';
      partOf = [ "podman-compose-photos-root.target" ];
      wantedBy = [ "podman-compose-photos-root.target" ];
    };

    # Volumes
    systemd.services."podman-volume-photos-immich-machine-learning-model-cache" = {
      path = [ pkgs.podman ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        podman volume inspect photos-immich-machine-learning-model-cache || podman volume create photos-immich-machine-learning-model-cache
      '';
      partOf = [ "podman-compose-photos-root.target" ];
      wantedBy = [ "podman-compose-photos-root.target" ];
    };

    # Root service
    # When started, this will automatically create all resources and start
    # the containers. When stopped, this will teardown all resources.
    systemd.targets."podman-compose-photos-root" = {
      unitConfig = {
        Description = "Root target generated by compose2nix.";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
