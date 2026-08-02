{
  pkgs,
  lib,
  config,
  ...
}:

let
  service = "opencloud";
  opencloud_port = 9200;
  opencloud_subdomain = service;
  opencloud_uri = "${opencloud_subdomain}.${config.modules.services.reverse-proxy.domain}";
  opencloud_uid = 1000;
  opencloud_gid = 1000;
  opencloud_data_dir = "${cfg.volumeDir}/data";
  opencloud_config_dir = "${cfg.volumeDir}/config";
  opencloud_ref_dir = "/etc/nixos/modules/services/opencloud/compose";
  euro_office_port = 9900;
  euro_office_subdomain = "euro-office";
  euro_office_uri = "${euro_office_subdomain}.${config.modules.services.reverse-proxy.domain}";
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
      "opencloud/opencloud/env" = { };
      "opencloud/euro-office/env" = { };
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.volumeDir} 0755 ${config.modules.base.userName} ${config.modules.base.groupName} - -"
      "d ${opencloud_data_dir} 0755 ${toString opencloud_uid} ${toString opencloud_gid} - -"
      "d ${opencloud_config_dir} 0755 ${toString opencloud_uid} ${toString opencloud_gid} - -"
    ];

    services.${config.modules.services.reverse-proxy.service} = {
      virtualHosts."${opencloud_uri}".extraConfig = ''
        reverse_proxy localhost:${toString opencloud_port}
      '';
      virtualHosts."${euro_office_uri}".extraConfig = ''
        reverse_proxy localhost:${toString euro_office_port}
      '';
    };

    modules.services.dyndns-ovh.subdomains = [
      opencloud_subdomain
      euro_office_subdomain
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
    virtualisation.oci-containers.containers."opencloud-euro-office" = {
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
        "--network=opencloud_opencloud-net"
      ];
    };
    systemd.services."podman-opencloud-euro-office" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "podman-network-opencloud_opencloud-net.service"
      ];
      requires = [
        "podman-network-opencloud_opencloud-net.service"
      ];
      partOf = [
        "podman-compose-opencloud-root.target"
      ];
      wantedBy = [
        "podman-compose-opencloud-root.target"
      ];
    };
    virtualisation.oci-containers.containers."opencloud-opencloud" = {
      image = "docker.io/opencloudeu/opencloud-rolling:latest";
      environment = {
        "COLLABORATION_APP_ADDR" = "https://${euro_office_uri}";
        "COLLABORATION_APP_ICON" =
          "https://${euro_office_uri}/web-apps/apps/documenteditor/main/resources/img/favicon.ico";
        "COLLABORATION_APP_INSECURE" = "true";
        "COLLABORATION_APP_NAME" = "Euro-Office";
        "COLLABORATION_APP_PRODUCT" = "OnlyOffice";
        "COLLABORATION_APP_PROOF_DISABLE" = "true";
        "COLLABORATION_CS3API_DATAGATEWAY_INSECURE" = "true";
        "COLLABORATION_WOPI_SRC" = "https://${opencloud_uri}";
        "EURO_OFFICE_DOMAIN" = euro_office_uri;
        "FRONTEND_ARCHIVER_MAX_SIZE" = "10000000000";
        "FRONTEND_CHECK_FOR_UPDATES" = "true";
        "IDM_CREATE_DEMO_USERS" = "false";
        "NOTIFICATIONS_SMTP_AUTHENTICATION" = "";
        "NOTIFICATIONS_SMTP_ENCRYPTION" = "none";
        "NOTIFICATIONS_SMTP_HOST" = "";
        "NOTIFICATIONS_SMTP_INSECURE" = "false";
        "NOTIFICATIONS_SMTP_PASSWORD" = "";
        "NOTIFICATIONS_SMTP_PORT" = "";
        "NOTIFICATIONS_SMTP_SENDER" = "OpenCloud Notifications <notifications@cloud.opencloud.test>";
        "NOTIFICATIONS_SMTP_USERNAME" = "";
        "OC_ADD_RUN_SERVICES" = "collaboration";
        "OC_DEFAULT_LANGUAGE" = "";
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
        "OC_URL" = "https://${opencloud_uri}";
        "PROXY_CSP_CONFIG_FILE_LOCATION" = "/etc/opencloud/csp.yaml";
        "PROXY_ENABLE_BASIC_AUTH" = "false";
        "PROXY_HTTP_ADDR" = "0.0.0.0:9200";
        "PROXY_TLS" = "false";
        "TRAEFIK_PORT_HTTPS" = "";
      };
      environmentFiles = [
        config.sops.secrets."opencloud/opencloud/env".path
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
        "compose2nix.settings.sops.secrets" = "opencloud/opencloud/env";
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
        "--network=opencloud_opencloud-net"
      ];
    };
    systemd.services."podman-opencloud-opencloud" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "podman-network-opencloud_opencloud-net.service"
      ];
      requires = [
        "podman-network-opencloud_opencloud-net.service"
      ];
      partOf = [
        "podman-compose-opencloud-root.target"
      ];
      wantedBy = [
        "podman-compose-opencloud-root.target"
      ];
    };

    # Networks
    systemd.services."podman-network-opencloud_opencloud-net" = {
      path = [ pkgs.podman ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "podman network rm -f opencloud_opencloud-net";
      };
      script = ''
        podman network inspect opencloud_opencloud-net || podman network create opencloud_opencloud-net
      '';
      partOf = [ "podman-compose-opencloud-root.target" ];
      wantedBy = [ "podman-compose-opencloud-root.target" ];
    };

    # Root service
    # When started, this will automatically create all resources and start
    # the containers. When stopped, this will teardown all resources.
    systemd.targets."podman-compose-opencloud-root" = {
      unitConfig = {
        Description = "Root target generated by compose2nix.";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
