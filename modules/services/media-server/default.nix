{
  pkgs,
  lib,
  config,
  ...
}:

let
  data_dir = "${cfg.volumeDir}/data";
  media_dir = "${data_dir}/media";
  torrents_dir = "${data_dir}/torrents";
  uid = config.modules.base.uid;
  gid = config.modules.base.gid;
  timezone = config.modules.base.timeZone;
  bazarr_port = 6767;
  bazarr_volume_dir = "${cfg.volumeDir}/bazarr";
  bazarr_config_dir = "${bazarr_volume_dir}/config";
  clonarr_port = 6060;
  clonarr_volume_dir = "${cfg.volumeDir}/clonarr";
  clonarr_config_dir = "${clonarr_volume_dir}/config";
  filebrowser_port = 8282;
  filebrowser_subdomain = "filebrowser";
  filebrowser_uri = "${filebrowser_subdomain}.${config.modules.services.reverse-proxy.domain}";
  filebrowser_volume_dir = "${cfg.volumeDir}/filebrowser";
  filebrowser_config_dir = "${filebrowser_volume_dir}/config";
  filebrowser_database_dir = "${filebrowser_volume_dir}/database";
  gluetun_vpn_open_port = 47563;
  gluetun_volume_dir = "${cfg.volumeDir}/gluetun";
  gluetun_gluetun_dir = "${gluetun_volume_dir}/gluetun";
  jellyfin_port = 8096;
  jellyfin_subdomain = "jellyfin";
  jellyfin_uri = "${jellyfin_subdomain}.${config.modules.services.reverse-proxy.domain}";
  jellyfin_volume_dir = "${cfg.volumeDir}/jellyfin";
  jellyfin_config_dir = "${jellyfin_volume_dir}/config";
  prowlarr_port = 9696;
  prowlarr_volume_dir = "${cfg.volumeDir}/prowlarr";
  prowlarr_config_dir = "${prowlarr_volume_dir}/config";
  qbit_manage_port = 8181;
  qbit_manage_volume_dir = "${cfg.volumeDir}/qbit-manage";
  qbit_manage_config_dir = "${qbit_manage_volume_dir}/config";
  qbittorrent_port = 8080;
  qbittorrent_volume_dir = "${cfg.volumeDir}/qbittorrent";
  qbittorrent_config_dir = "${qbittorrent_volume_dir}/config";
  radarr_port = 7878;
  radarr_volume_dir = "${cfg.volumeDir}/radarr";
  radarr_config_dir = "${radarr_volume_dir}/config";
  seerr_port = 5055;
  seerr_subdomain = "seerr";
  seerr_uri = "${seerr_subdomain}.${config.modules.services.reverse-proxy.domain}";
  seerr_uid = 1000;
  seerr_gid = 1000;
  seerr_volume_dir = "${cfg.volumeDir}/seerr";
  seerr_config_dir = "${seerr_volume_dir}/config";
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
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."media-server/gluetun/env" = { };

    systemd.tmpfiles.rules = [
      "d ${data_dir} 0755 ${toString uid} ${toString gid} - -"
      "d ${media_dir} 0755 ${toString uid} ${toString gid} - -"
      "d ${torrents_dir} 0755 ${toString uid} ${toString gid} - -"
      "d ${bazarr_volume_dir} 0755 ${toString uid} ${toString gid} - -"
      "d ${bazarr_config_dir} 0755 ${toString uid} ${toString gid} - -"
      "d ${clonarr_volume_dir} 0755 ${toString uid} ${toString gid} - -"
      "d ${clonarr_config_dir} 0755 ${toString uid} ${toString gid} - -"
      "d ${filebrowser_volume_dir} 0755 ${toString uid} ${toString gid} - -"
      "d ${filebrowser_config_dir} 0755 ${toString uid} ${toString gid} - -"
      "d ${filebrowser_database_dir} 0755 ${toString uid} ${toString gid} - -"
      "d ${gluetun_volume_dir} 0755 ${toString uid} ${toString gid} - -"
      "d ${gluetun_gluetun_dir} 0755 ${toString uid} ${toString gid} - -"
      "d ${jellyfin_volume_dir} 0755 ${toString uid} ${toString gid} - -"
      "d ${jellyfin_config_dir} 0755 ${toString uid} ${toString gid} - -"
      "d ${prowlarr_volume_dir} 0755 ${toString uid} ${toString gid} - -"
      "d ${prowlarr_config_dir} 0755 ${toString uid} ${toString gid} - -"
      "d ${qbit_manage_volume_dir} 0755 ${toString uid} ${toString gid} - -"
      "d ${qbit_manage_config_dir} 0755 ${toString uid} ${toString gid} - -"
      "d ${qbittorrent_volume_dir} 0755 ${toString uid} ${toString gid} - -"
      "d ${qbittorrent_config_dir} 0755 ${toString uid} ${toString gid} - -"
      "d ${radarr_volume_dir} 0755 ${toString uid} ${toString gid} - -"
      "d ${radarr_config_dir} 0755 ${toString uid} ${toString gid} - -"
      "d ${seerr_volume_dir} 0755 ${toString seerr_uid} ${toString seerr_gid} - -"
      "d ${seerr_config_dir} 0755 ${toString seerr_uid} ${toString seerr_gid} - -"
      "d ${sonarr_volume_dir} 0755 ${toString uid} ${toString gid} - -"
      "d ${sonarr_config_dir} 0755 ${toString uid} ${toString gid} - -"
    ];

    networking.firewall.allowedTCPPorts = [
      bazarr_port
      clonarr_port
      prowlarr_port
      qbit_manage_port
      qbittorrent_port
      radarr_port
      sonarr_port
    ];

    services.${config.modules.services.reverse-proxy.service} = {
      virtualHosts."${filebrowser_uri}".extraConfig = ''
        reverse_proxy localhost:${toString filebrowser_port}
      '';

      virtualHosts."${jellyfin_uri}".extraConfig = ''
        reverse_proxy localhost:${toString jellyfin_port}
      '';

      virtualHosts."${seerr_uri}".extraConfig = ''
        reverse_proxy localhost:${toString seerr_port}
      '';
    };

    modules.services.dyndns-ovh.subdomains = [
      filebrowser_subdomain
      jellyfin_subdomain
      seerr_subdomain
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
    virtualisation.oci-containers.containers."media-server-filebrowser" = {
      image = "docker.io/filebrowser/filebrowser:s6";
      environment = {
        "PGID" = toString gid;
        "PUID" = toString uid;
      };
      volumes = [
        "${media_dir}:/srv:rw"
        "${filebrowser_config_dir}:/config:rw"
        "${filebrowser_database_dir}:/database:rw"
      ];
      ports = [
        "${toString filebrowser_port}:80/tcp"
      ];
      labels = {
        "io.containers.autoupdate" = "registry";
      };
      log-driver = "journald";
      extraOptions = [
        "--network-alias=filebrowser"
        "--network=media-server"
      ];
    };
    systemd.services."podman-media-server-filebrowser" = {
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
        "FIREWALL_VPN_INPUT_PORTS" = toString gluetun_vpn_open_port;
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
    virtualisation.oci-containers.containers."media-server-jellyfin" = {
      image = "lscr.io/linuxserver/jellyfin:latest";
      environment = {
        "DOCKER_MODS" = "linuxserver/mods:jellyfin-opencl-intel";
        "PGID" = toString gid;
        "PUID" = toString uid;
        "TZ" = timezone;
      };
      volumes = [
        "${jellyfin_config_dir}:/config:rw"
        "${media_dir}:/data/media:rw"
      ];
      ports = [
        "${toString jellyfin_port}:8096/tcp"
      ];
      labels = {
        "io.containers.autoupdate" = "registry";
      };
      log-driver = "journald";
      extraOptions = [
        "--device=/dev/dri:/dev/dri:rwm"
        "--network-alias=jellyfin"
        "--network=media-server"
      ];
    };
    systemd.services."podman-media-server-jellyfin" = {
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
    virtualisation.oci-containers.containers."media-server-qbit-manage" = {
      image = "ghcr.io/stuffanthings/qbit_manage:latest";
      environment = {
        "PGID" = toString gid;
        "PUID" = toString uid;
        "QBT_PORT" = "${toString qbit_manage_port}";
        "QBT_WEB_SERVER" = "true";
        "TZ" = timezone;
      };
      volumes = [
        "${torrents_dir}:/data/torrents:rw"
        "${qbit_manage_config_dir}:/config:rw"
        "${qbittorrent_volume_dir}:/qbittorrent:ro"
      ];
      ports = [
        "${toString qbit_manage_port}:${toString qbit_manage_port}/tcp"
      ];
      labels = {
        "io.containers.autoupdate" = "registry";
      };
      log-driver = "journald";
      extraOptions = [
        "--network-alias=qbit-manage"
        "--network=media-server"
      ];
    };
    systemd.services."podman-media-server-qbit-manage" = {
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
        "TORRENTING_PORT" = toString gluetun_vpn_open_port;
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
    virtualisation.oci-containers.containers."media-server-seerr" = {
      image = "docker.io/seerr/seerr:latest";
      environment = {
        "TZ" = timezone;
      };
      volumes = [
        "${seerr_config_dir}:/app/config:rw"
      ];
      ports = [
        "${toString seerr_port}:5055/tcp"
      ];
      labels = {
        "io.containers.autoupdate" = "registry";
      };
      log-driver = "journald";
      extraOptions = [
        "--network-alias=seerr"
        "--network=media-server"
      ];
    };
    systemd.services."podman-media-server-seerr" = {
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
