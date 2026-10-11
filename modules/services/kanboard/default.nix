{
  pkgs,
  lib,
  config,
  ...
}:

let
  service = "kanboard";
  kanboard_port = 8383;
  kanboard_subdomain = service;
  kanboard_uri = "${kanboard_subdomain}.${config.modules.services.reverse-proxy.domain}";
  kanboard_uid = 0;
  kanboard_gid = 0;
  kanboard_volume_dir = "${cfg.volumeDir}/kanboard";
  kanboard_certs_dir = "${kanboard_volume_dir}/certs";
  kanboard_data_dir = "${kanboard_volume_dir}/data";
  kanboard_plugins_dir = "${kanboard_volume_dir}/plugins";
  postgres_uid = 999;
  postgres_gid = 999;
  postgres_volume_dir = "${cfg.volumeDir}/postgres";
  postgres_sql_dir = "${cfg.volumeDir}/postgresql";
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
    sops.secrets."kanboard/kanboard/env" = { };
    sops.secrets."kanboard/postgres/env" = { };

    systemd.tmpfiles.rules = [
      "d ${cfg.volumeDir} 0755 ${config.modules.base.userName} ${config.modules.base.groupName} - -"
      "d ${kanboard_volume_dir} 0755 ${toString kanboard_uid} ${toString kanboard_gid} - -"
      "d ${kanboard_certs_dir} 0755 ${toString kanboard_uid} ${toString kanboard_gid} - -"
      "d ${kanboard_data_dir} 0755 ${toString kanboard_uid} ${toString kanboard_gid} - -"
      "d ${kanboard_plugins_dir} 0755 ${toString kanboard_uid} ${toString kanboard_gid} - -"
      "d ${postgres_volume_dir} 0755 ${toString postgres_uid} ${toString postgres_gid} - -"
      "d ${postgres_sql_dir} 0755 ${toString postgres_uid} ${toString postgres_gid} - -"
    ];

    services.${config.modules.services.reverse-proxy.service} = {
      virtualHosts."${kanboard_uri}".extraConfig = ''
        reverse_proxy localhost:${toString kanboard_port}
      '';
    };

    modules.services.dyndns-ovh.subdomains = [ kanboard_subdomain ];

    # Containers
    virtualisation.oci-containers.containers."kanboard-kanboard" = {
      image = "docker.io/kanboard/kanboard:latest";
      environment = {
        "DB_DRIVER" = "postgres";
        "DB_HOSTNAME" = "postgres";
        "MAIL_SMTP_ENCRYPTION" = "tls";
        "MAIL_SMTP_FROM" = "${service}@${config.modules.services.reverse-proxy.domain}";
        "MAIL_SMTP_HOST" = config.programs.msmtp.accounts.default.host;
        "MAIL_SMTP_PORT" = toString config.programs.msmtp.accounts.default.port;
        "MAIL_SMTP_USERNAME" = config.programs.msmtp.accounts.default.user;
        "PLUGIN_INSTALLER" = "true";
      };
      environmentFiles = [
        config.sops.secrets."kanboard/kanboard/env".path
      ];
      volumes = [
        "${kanboard_certs_dir}:/etc/nginx/ssl:rw"
        "${kanboard_data_dir}:/var/www/app/data:rw"
        "${kanboard_plugins_dir}:/var/www/app/plugins:rw"
      ];
      ports = [
        "${toString kanboard_port}:80/tcp"
      ];
      labels = {
        "compose2nix.settings.sops.secrets" = "kanboard/kanboard/env";
        "io.containers.autoupdate" = "registry";
      };
      dependsOn = [
        "kanboard-postgres"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network-alias=app"
        "--network=kanboard"
      ];
    };
    systemd.services."podman-kanboard-kanboard" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "podman-network-kanboard.service"
      ];
      requires = [
        "podman-network-kanboard.service"
      ];
      partOf = [
        "podman-compose-kanboard-root.target"
      ];
      wantedBy = [
        "podman-compose-kanboard-root.target"
      ];
    };
    virtualisation.oci-containers.containers."kanboard-postgres" = {
      image = "docker.io/library/postgres:latest";
      environment = {
        "POSTGRES_DB" = "kanboard";
      };
      environmentFiles = [
        config.sops.secrets."kanboard/postgres/env".path
      ];
      volumes = [
        "${postgres_volume_dir}:/var/lib/postgresql:rw"
      ];
      labels = {
        "compose2nix.settings.sops.secrets" = "kanboard/postgres/env";
        "io.containers.autoupdate" = "registry";
      };
      log-driver = "journald";
      extraOptions = [
        "--network-alias=postgres"
        "--network=kanboard"
      ];
    };
    systemd.services."podman-kanboard-postgres" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "podman-network-kanboard.service"
      ];
      requires = [
        "podman-network-kanboard.service"
      ];
      partOf = [
        "podman-compose-kanboard-root.target"
      ];
      wantedBy = [
        "podman-compose-kanboard-root.target"
      ];
    };

    # Networks
    systemd.services."podman-network-kanboard" = {
      path = [ pkgs.podman ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "podman network rm -f kanboard";
      };
      script = ''
        podman network inspect kanboard || podman network create kanboard
      '';
      partOf = [ "podman-compose-kanboard-root.target" ];
      wantedBy = [ "podman-compose-kanboard-root.target" ];
    };

    # Root service
    # When started, this will automatically create all resources and start
    # the containers. When stopped, this will teardown all resources.
    systemd.targets."podman-compose-kanboard-root" = {
      unitConfig = {
        Description = "Root target generated by compose2nix.";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
