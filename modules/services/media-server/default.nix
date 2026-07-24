{
  pkgs,
  lib,
  config,
  ...
}:

let
  media_dir = "${cfg.volumeDir}/media";
  torrents_dir = "${cfg.volumeDir}/torrents";
  uid = config.modules.base.uid;
  gid = config.modules.base.gid;
  timezone = config.modules.base.timeZone;
  data_dir = "${cfg.volumeDir}";
  bazarr_port = 6767;
  bazarr_volume_dir = "${cfg.volumeDir}/bazarr";
  bazarr_config_dir = "${bazarr_volume_dir}/config";
  clonarr_port = 6060;
  clonarr_volume_dir = "${cfg.volumeDir}/clonarr";
  clonarr_config_dir = "${clonarr_volume_dir}/config";
  gluetun_volume_dir = "${cfg.volumeDir}/gluetun";
  gluetun_gluetun_dir = "${gluetun_volume_dir}/gluetun";
  prowlarr_port = 9696;
  prowlarr_volume_dir = "${cfg.volumeDir}/prowlarr";
  prowlarr_config_dir = "${prowlarr_volume_dir}/config";
  qbittorrent_port = 8080;
  qbittorrent_volume_dir = "${cfg.volumeDir}/qbittorrent";
  qbittorrent_config_dir = "${qbittorrent_volume_dir}/config";
  radarr_port = 7878;
  radarr_volume_dir = "${cfg.volumeDir}/radarr";
  radarr_config_dir = "${radarr_volume_dir}/config";
  sonarr_port = 8989;
  sonarr_volume_dir = "${cfg.volumeDir}/sonarr";
  sonarr_config_dir = "${sonarr_volume_dir}/config";
  utils = import ../../../utils;
  cfg = config.modules.services.media-server;
in
{
  imports = utils.importSubmodules { dir = ./.; };

  options.modules.services.media-server = {
    enable = lib.mkEnableOption "Whether to enable custom media server settings.";

    volumeDir = lib.mkOption {
      type = lib.types.path;
    };

    torrentingPort = lib.mkOption {
      type = lib.types.int;
    };
  };

  config = lib.mkIf cfg.enable {
    modules.services.media-server = {
      cross-seed.enable = true;
      filebrowser = {
        enable = true;
        rootDir = "${media_dir}";
      };
      flaresolverr.enable = true;
      jellyfin.enable = true;
      seerr.enable = true;
    };

    sops.secrets."media-server/gluetun/env" = { };

    systemd.tmpfiles.rules = [
      "d ${cfg.volumeDir} 0755 ${toString uid} ${toString gid} - -"
      "d ${media_dir} 0755 ${toString uid} ${toString gid} - -"
      "d ${torrents_dir} 0755 ${toString uid} ${toString gid} - -"
      "d ${bazarr_volume_dir} 0755 ${toString uid} ${toString gid} - -"
      "d ${bazarr_config_dir} 0755 ${toString uid} ${toString gid} - -"
      "d ${clonarr_volume_dir} 0755 ${toString uid} ${toString gid} - -"
      "d ${clonarr_config_dir} 0755 ${toString uid} ${toString gid} - -"
      "d ${gluetun_volume_dir} 0755 ${toString uid} ${toString gid} - -"
      "d ${gluetun_gluetun_dir} 0755 ${toString uid} ${toString gid} - -"
      "d ${prowlarr_volume_dir} 0755 ${toString uid} ${toString gid} - -"
      "d ${prowlarr_config_dir} 0755 ${toString uid} ${toString gid} - -"
      "d ${qbittorrent_volume_dir} 0755 ${toString uid} ${toString gid} - -"
      "d ${qbittorrent_config_dir} 0755 ${toString uid} ${toString gid} - -"
      "d ${radarr_volume_dir} 0755 ${toString uid} ${toString gid} - -"
      "d ${radarr_config_dir} 0755 ${toString uid} ${toString gid} - -"
      "d ${sonarr_volume_dir} 0755 ${toString uid} ${toString gid} - -"
      "d ${sonarr_config_dir} 0755 ${toString uid} ${toString gid} - -"
    ];

    networking.firewall.allowedTCPPorts = [
      bazarr_port
      clonarr_port
      prowlarr_port
      qbittorrent_port
      radarr_port
      sonarr_port
    ];

    # Containers
    virtualisation.oci-containers.containers."media-server-bazarr" = {
      image = "lscr.io/linuxserver/bazarr:latest";
      environment = {
        "PGID" = toString gid;
        "PUID" = toString uid;
        "TZ" = timezone;
      };
      volumes = [
        "${bazarr_config_dir}:/config:rw"
        "${media_dir}:/data/media:rw"
      ];
      ports = [
        "${toString bazarr_port}:6767/tcp"
      ];
      labels = {
        "io.containers.autoupdate" = "registry";
      };
      log-driver = "journald";
      extraOptions = [
        "--network-alias=bazarr"
        "--network=media-server"
      ];
    };
    systemd.services."podman-media-server-bazarr" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "podman-network-media-server.service"
      ];
      requires = [
        "podman-network-media-server.service"
      ];
      partOf = [
        "podman-compose-media-server-root.target"
      ];
      wantedBy = [
        "podman-compose-media-server-root.target"
      ];
    };
    virtualisation.oci-containers.containers."media-server-clonarr" = {
      image = "ghcr.io/prophetse7en/clonarr:latest";
      environment = {
        "PGID" = toString gid;
        "PUID" = toString uid;
        "TZ" = timezone;
      };
      volumes = [
        "${clonarr_config_dir}:/config:rw"
      ];
      ports = [
        "${toString clonarr_port}:6060/tcp"
      ];
      labels = {
        "io.containers.autoupdate" = "registry";
      };
      log-driver = "journald";
      extraOptions = [
        "--network-alias=clonarr"
        "--network=media-server"
      ];
    };
    systemd.services."podman-media-server-clonarr" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "podman-network-media-server.service"
      ];
      requires = [
        "podman-network-media-server.service"
      ];
      partOf = [
        "podman-compose-media-server-root.target"
      ];
      wantedBy = [
        "podman-compose-media-server-root.target"
      ];
    };
    virtualisation.oci-containers.containers."media-server-gluetun" = {
      image = "docker.io/qmcgaw/gluetun:v3";
      environment = {
        "FIREWALL_VPN_INPUT_PORTS" = toString cfg.torrentingPort;
        "PGID" = toString gid;
        "PUID" = toString uid;
        "SERVER_COUNTRIES" = "Netherlands";
        "TZ" = timezone;
        "UPDATER_PERIOD" = "480h";
        "VPN_SERVICE_PROVIDER" = "airvpn";
        "VPN_TYPE" = "wireguard";
      };
      environmentFiles = [
        config.sops.secrets."media-server/gluetun/env".path
      ];
      volumes = [
        "${gluetun_gluetun_dir}:/gluetun:rw"
      ];
      ports = [
        "${toString qbittorrent_port}:${toString qbittorrent_port}/tcp"
      ];
      labels = {
        "compose2nix.settings.sops.secrets" = "media-server/gluetun/env";
        "io.containers.autoupdate" = "registry";
      };
      log-driver = "journald";
      extraOptions = [
        "--cap-add=NET_ADMIN"
        "--cap-add=NET_RAW"
        "--device=/dev/net/tun:/dev/net/tun:rwm"
        "--network-alias=gluetun"
        "--network=media-server"
      ];
    };
    systemd.services."podman-media-server-gluetun" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "podman-network-media-server.service"
      ];
      requires = [
        "podman-network-media-server.service"
      ];
      partOf = [
        "podman-compose-media-server-root.target"
      ];
      wantedBy = [
        "podman-compose-media-server-root.target"
      ];
    };
    virtualisation.oci-containers.containers."media-server-prowlarr" = {
      image = "lscr.io/linuxserver/prowlarr:latest";
      environment = {
        "PGID" = toString gid;
        "PUID" = toString uid;
        "TZ" = timezone;
      };
      volumes = [
        "${prowlarr_config_dir}:/config:rw"
      ];
      ports = [
        "${toString prowlarr_port}:9696/tcp"
      ];
      labels = {
        "io.containers.autoupdate" = "registry";
      };
      log-driver = "journald";
      extraOptions = [
        "--network-alias=prowlarr"
        "--network=media-server"
      ];
    };
    systemd.services."podman-media-server-prowlarr" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "podman-network-media-server.service"
      ];
      requires = [
        "podman-network-media-server.service"
      ];
      partOf = [
        "podman-compose-media-server-root.target"
      ];
      wantedBy = [
        "podman-compose-media-server-root.target"
      ];
    };
    virtualisation.oci-containers.containers."media-server-qbittorrent" = {
      image = "lscr.io/linuxserver/qbittorrent:latest";
      environment = {
        "DOCKER_MODS" = "ghcr.io/vuetorrent/vuetorrent-lsio-mod:latest";
        "PGID" = toString gid;
        "PUID" = toString uid;
        "TORRENTING_PORT" = toString cfg.torrentingPort;
        "TZ" = timezone;
        "WEBUI_PORT" = toString qbittorrent_port;
      };
      volumes = [
        "${qbittorrent_config_dir}:/config:rw"
        "${torrents_dir}:/data/torrents:rw"
      ];
      labels = {
        "io.containers.autoupdate" = "registry";
      };
      dependsOn = [
        "media-server-gluetun"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network=container:media-server-gluetun"
      ];
    };
    systemd.services."podman-media-server-qbittorrent" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      partOf = [
        "podman-compose-media-server-root.target"
      ];
      wantedBy = [
        "podman-compose-media-server-root.target"
      ];
    };
    virtualisation.oci-containers.containers."media-server-radarr" = {
      image = "lscr.io/linuxserver/radarr:latest";
      environment = {
        "PGID" = toString gid;
        "PUID" = toString uid;
        "TZ" = timezone;
      };
      volumes = [
        "${data_dir}:/data:rw"
        "${radarr_config_dir}:/config:rw"
      ];
      ports = [
        "${toString radarr_port}:7878/tcp"
      ];
      labels = {
        "io.containers.autoupdate" = "registry";
      };
      log-driver = "journald";
      extraOptions = [
        "--network-alias=radarr"
        "--network=media-server"
      ];
    };
    systemd.services."podman-media-server-radarr" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "podman-network-media-server.service"
      ];
      requires = [
        "podman-network-media-server.service"
      ];
      partOf = [
        "podman-compose-media-server-root.target"
      ];
      wantedBy = [
        "podman-compose-media-server-root.target"
      ];
    };
    virtualisation.oci-containers.containers."media-server-sonarr" = {
      image = "lscr.io/linuxserver/sonarr:latest";
      environment = {
        "PGID" = toString gid;
        "PUID" = toString uid;
        "TZ" = timezone;
      };
      volumes = [
        "${data_dir}:/data:rw"
        "${sonarr_config_dir}:/config:rw"
      ];
      ports = [
        "${toString sonarr_port}:8989/tcp"
      ];
      labels = {
        "io.containers.autoupdate" = "registry";
      };
      log-driver = "journald";
      extraOptions = [
        "--network-alias=sonarr"
        "--network=media-server"
      ];
    };
    systemd.services."podman-media-server-sonarr" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "podman-network-media-server.service"
      ];
      requires = [
        "podman-network-media-server.service"
      ];
      partOf = [
        "podman-compose-media-server-root.target"
      ];
      wantedBy = [
        "podman-compose-media-server-root.target"
      ];
    };

    # Networks
    systemd.services."podman-network-media-server" = {
      path = [ pkgs.podman ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "podman network rm -f media-server";
      };
      script = ''
        podman network inspect media-server || podman network create media-server
      '';
      partOf = [ "podman-compose-media-server-root.target" ];
      wantedBy = [ "podman-compose-media-server-root.target" ];
    };

    # Root service
    # When started, this will automatically create all resources and start
    # the containers. When stopped, this will teardown all resources.
    systemd.targets."podman-compose-media-server-root" = {
      unitConfig = {
        Description = "Root target generated by compose2nix.";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
