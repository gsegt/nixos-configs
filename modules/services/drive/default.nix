{
  pkgs,
  lib,
  config,
  ...
}:

let
  service = "drive";
  subdomain = service;
  uri = "${subdomain}.${config.modules.services.reverse-proxy.domain}";
  office_subdomain = "office";
  office_uri = "${office_subdomain}.${config.modules.services.reverse-proxy.domain}";
  opencloud_volume_dir = "${cfg.volumeDir}/opencloud";
  opencloud_data_dir = "${opencloud_volume_dir}/data";
  opencloud_config_dir = "${opencloud_volume_dir}/config";
  opencloud_uid = 1000;
  opencloud_gid = 1000;
  opencloud_port = 9200;
  opencloud_ref_dir = "/etc/nixos/modules/services/drive/compose";
  euro_office_port = 9900;
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
      "drive/opencloud/env" = { };
      "drive/euro-office/env" = { };
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.volumeDir} 0755 ${config.modules.base.userName} ${config.modules.base.groupName} - -"
      "d ${opencloud_volume_dir} 0755 ${toString opencloud_uid} ${toString opencloud_gid} - -"
      "d ${opencloud_data_dir} 0755 ${toString opencloud_uid} ${toString opencloud_gid} - -"
      "d ${opencloud_config_dir} 0755 ${toString opencloud_uid} ${toString opencloud_gid} - -"
    ];

    services.${config.modules.services.reverse-proxy.service} = {
      virtualHosts."${uri}".extraConfig = ''
        reverse_proxy localhost:${toString opencloud_port}
      '';
      virtualHosts."${office_uri}".extraConfig = ''
        reverse_proxy localhost:${toString euro_office_port}
      '';
    };

    modules.services.dyndns-ovh.subdomains = [
      subdomain
      office_subdomain
    ];

    fileSystems."/usr/share/fonts/truetype" =
      let
        fontDir = pkgs.symlinkJoin {
          name = "euro-office-fonts";
          paths = with pkgs; [
            corefonts
          ];
        };
      in
      {
        device = "${fontDir}/share/fonts";
        fsType = "none";
        options = [ "bind" ];
      };

    # Containers
    virtualisation.oci-containers.containers."drive-euro-office" = {
      image = "ghcr.io/euro-office/documentserver:latest";
      environment = {
        "USE_UNAUTHORIZED_STORAGE" = "false";
        "WOPI_ENABLED" = "true";
      };
      volumes = [
        "/usr/share/fonts/truetype:/usr/share/fonts/truetype/more:ro"
      ];
      ports = [
        "127.0.0.1:${toString euro_office_port}:80/tcp"
      ];
      labels = {
        "compose2nix.settings.sops.secrets" = "opencloud/euro-office/env";
        "io.containers.autoupdate" = "registry";
      };
      log-driver = "journald";
      extraOptions = [
        "--network-alias=euro-office"
        "--network=drive_opencloud-net"
      ];
    };
    systemd.services."podman-drive-euro-office" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "podman-network-drive_opencloud-net.service"
      ];
      requires = [
        "podman-network-drive_opencloud-net.service"
      ];
      partOf = [
        "podman-compose-drive-root.target"
      ];
      wantedBy = [
        "podman-compose-drive-root.target"
      ];
    };
    virtualisation.oci-containers.containers."drive-opencloud" = {
      image = "docker.io/opencloudeu/opencloud-rolling:latest";
      environment = {
        "COLLABORATION_APP_ADDR" = "https://${office_uri}";
        "COLLABORATION_APP_ICON" =
          "https://${office_uri}/web-apps/apps/documenteditor/main/resources/img/favicon.ico";
        "COLLABORATION_APP_INSECURE" = "true";
        "COLLABORATION_APP_NAME" = "Euro-Office";
        "COLLABORATION_APP_PRODUCT" = "OnlyOffice";
        "COLLABORATION_APP_PROOF_DISABLE" = "true";
        "COLLABORATION_CS3API_DATAGATEWAY_INSECURE" = "true";
        "COLLABORATION_WOPI_SRC" = "https://${uri}";
        "EURO_OFFICE_DOMAIN" = office_uri;
        "FRONTEND_ARCHIVER_MAX_SIZE" = "10000000000";
        "FRONTEND_CHECK_FOR_UPDATES" = "true";
        "IDM_CREATE_DEMO_USERS" = "false";
        "NOTIFICATIONS_SMTP_AUTHENTICATION" = "";
        "NOTIFICATIONS_SMTP_ENCRYPTION" = "starttls";
        "NOTIFICATIONS_SMTP_HOST" = "smtp.mail.ovh.net";
        "NOTIFICATIONS_SMTP_INSECURE" = "false";
        "NOTIFICATIONS_SMTP_PORT" = "587";
        "NOTIFICATIONS_SMTP_SENDER" = "OpenCloud Notifications <drive@gsegt.eu>";
        "NOTIFICATIONS_SMTP_USERNAME" = "mail@gsegt.eu";
        "OC_ADD_RUN_SERVICES" = "notifications,collaboration";
        "OC_DEFAULT_LANGUAGE" = "en";
        "OC_ENABLE_GUEST_LINKS" = "false";
        "OC_INSECURE" = "false";
        "OC_LOG_COLOR" = "false";
        "OC_LOG_LEVEL" = "info";
        "OC_LOG_PRETTY" = "false";
        "OC_PASSWORD_POLICY_BANNED_PASSWORDS_LIST" = "banned-password-list.txt";
        "OC_PASSWORD_POLICY_DISABLED" = "false";
        "OC_PASSWORD_POLICY_MIN_CHARACTERS" = "8";
        "OC_PASSWORD_POLICY_MIN_DIGITS" = "1";
        "OC_PASSWORD_POLICY_MIN_LOWERCASE_CHARACTERS" = "1";
        "OC_PASSWORD_POLICY_MIN_SPECIAL_CHARACTERS" = "1";
        "OC_PASSWORD_POLICY_MIN_UPPERCASE_CHARACTERS" = "1";
        "OC_SHARING_PUBLIC_SHARE_MUST_HAVE_PASSWORD" = "true";
        "OC_SHARING_PUBLIC_WRITEABLE_SHARE_MUST_HAVE_PASSWORD" = "false";
        "OC_URL" = "https://${uri}";
        "PROXY_CSP_CONFIG_FILE_LOCATION" = "/etc/opencloud/csp.yaml";
        "PROXY_ENABLE_BASIC_AUTH" = "false";
        "PROXY_HTTP_ADDR" = "0.0.0.0:9200";
        "PROXY_TLS" = "false";
        "TRAEFIK_PORT_HTTPS" = "";
      };
      environmentFiles = [
        config.sops.secrets."drive/opencloud/env".path
      ];
      volumes = [
        "${opencloud_ref_dir}/config/euro-office/app-registry.yaml:/etc/opencloud/app-registry.yaml:rw"
        "${opencloud_ref_dir}/config/opencloud/apps:/var/lib/opencloud/web/assets/apps:rw"
        "${opencloud_ref_dir}/config/opencloud/apps.yaml:/etc/opencloud/apps.yaml:rw"
        "${opencloud_ref_dir}/config/opencloud/banned-password-list.txt:/etc/opencloud/banned-password-list.txt:rw"
        "${opencloud_ref_dir}/config/opencloud/csp.yaml:/etc/opencloud/csp.yaml:rw"
        "${opencloud_config_dir}:/etc/opencloud:rw"
        "${opencloud_data_dir}:/var/lib/opencloud:rw"
      ];
      ports = [
        "127.0.0.1:${toString opencloud_port}:9200/tcp"
      ];
      labels = {
        "compose2nix.settings.sops.secrets" = "drive/opencloud/env";
        "io.containers.autoupdate" = "registry";
      };
      cmd = [
        "-c"
        "opencloud init || true; opencloud server"
      ];
      user = "1000:1000";
      log-driver = "journald";
      extraOptions = [
        "--entrypoint=[\"/bin/sh\"]"
        "--network-alias=opencloud"
        "--network=drive_opencloud-net"
      ];
    };
    systemd.services."podman-drive-opencloud" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "podman-network-drive_opencloud-net.service"
      ];
      requires = [
        "podman-network-drive_opencloud-net.service"
      ];
      partOf = [
        "podman-compose-drive-root.target"
      ];
      wantedBy = [
        "podman-compose-drive-root.target"
      ];
    };

    # Networks
    systemd.services."podman-network-drive_opencloud-net" = {
      path = [ pkgs.podman ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "podman network rm -f drive_opencloud-net";
      };
      script = ''
        podman network inspect drive_opencloud-net || podman network create drive_opencloud-net
      '';
      partOf = [ "podman-compose-drive-root.target" ];
      wantedBy = [ "podman-compose-drive-root.target" ];
    };

    # Root service
    # When started, this will automatically create all resources and start
    # the containers. When stopped, this will teardown all resources.
    systemd.targets."podman-compose-drive-root" = {
      unitConfig = {
        Description = "Root target generated by compose2nix.";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
