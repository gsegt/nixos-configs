{
  pkgs,
  lib,
  config,
  ...
}:

let
  service = "opencloud";
  opencloud_port = 9200;
  collabora_port = 9980;
  wopi_port = 9300;
  opencloud_uri = "${service}.${config.modules.services.reverse-proxy.domain}";
  collabora_uri = "collabora.${config.modules.services.reverse-proxy.domain}";
  wopi_uri = "wopi.${config.modules.services.reverse-proxy.domain}";
  opencloud_data_dir = "${cfg.volumeDir}/data";
  opencloud_config_dir = "${cfg.volumeDir}/config";
  opencloud_ref_dir = "/etc/nixos/modules/services/opencloud/compose";
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
    sops.secrets."opencloud/opencloud/env" = {
      owner = config.modules.base.userName;
      group = config.modules.base.groupName;
    };
    sops.secrets."opencloud/collabora/env" = {
      owner = config.modules.base.userName;
      group = config.modules.base.groupName;
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.volumeDir} 0755 ${config.modules.base.userName} ${config.modules.base.groupName} - -"
      "d ${opencloud_data_dir} 0755 ${config.modules.base.userName} ${config.modules.base.groupName} - -"
      "d ${opencloud_config_dir} 0755 ${config.modules.base.userName} ${config.modules.base.groupName} - -"
    ];

    services.${config.modules.services.reverse-proxy.service} = {
      virtualHosts."${opencloud_uri}".extraConfig = ''
        reverse_proxy localhost:${toString opencloud_port}
      '';
      virtualHosts."${collabora_uri}".extraConfig = ''
        reverse_proxy localhost:${toString collabora_port}
      '';
      virtualHosts."${wopi_uri}".extraConfig = ''
        reverse_proxy localhost:${toString wopi_port}
      '';
    };

    modules.services.dyndns-ovh.subdomains = [
      service
      "collabora"
      "wopi"
    ];

    fileSystems."/usr/share/fonts/truetype" =
      let
        fontDir = pkgs.symlinkJoin {
          name = "collabora-fonts";
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
    virtualisation.oci-containers.containers."opencloud-collabora" = {
      image = "docker.io/collabora/code:latest";
      environment = {
        "DONT_GEN_SSL_CERT" = "YES";
        "aliasgroup1" = "https://${wopi_uri}";
        "extra_params" =
          "--o:ssl.enable=false \\
            --o:ssl.ssl_verification=false \\
            --o:ssl.termination=true \\
            --o:welcome.enable=false \\
            --o:net.frame_ancestors=${opencloud_uri} \\
            --o:net.lok_allow.host[14]=${opencloud_uri} \\
            --o:home_mode.enable=false
          ";
        "username" = "admin";
      };
      environmentFiles = [
        config.sops.secrets."opencloud/collabora/env".path
      ];
      volumes = [
        "/usr/share/fonts/truetype:/opt/cool/systemplate/usr/share/fonts/truetype/more:ro"
      ];
      ports = [
        "127.0.0.1:${toString collabora_port}:9980/tcp"
      ];
      labels = {
        "compose2nix.settings.sops.secrets" = "opencloud/collabora/env";
        "io.containers.autoupdate" = "registry";
      };
      cmd = [ "coolconfig generate-proof-key && /start-collabora-online.sh" ];
      log-driver = "journald";
      extraOptions = [
        "--cap-add=SYS_ADMIN"
        "--entrypoint=[\"/bin/bash\", \"-c\"]"
        "--health-cmd=[\"curl\", \"-f\", \"http://localhost:9980/hosting/discovery\"]"
        "--health-interval=15s"
        "--health-retries=5"
        "--health-timeout=10s"
        "--network-alias=collabora"
        "--network=opencloud_opencloud-net"
        "--security-opt=apparmor:unconfined"
        "--security-opt=seccomp=unconfined"
      ];
    };
    systemd.services."podman-opencloud-collabora" = {
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
    virtualisation.oci-containers.containers."opencloud-collaboration" = {
      image = "docker.io/opencloudeu/opencloud-rolling:latest";
      environment = {
        "COLLABORATION_APP_ADDR" = "https://${collabora_uri}";
        "COLLABORATION_APP_ICON" = "https://${collabora_uri}/favicon.ico";
        "COLLABORATION_APP_INSECURE" = "true";
        "COLLABORATION_APP_NAME" = "CollaboraOnline";
        "COLLABORATION_APP_PRODUCT" = "Collabora";
        "COLLABORATION_CS3API_DATAGATEWAY_INSECURE" = "true";
        "COLLABORATION_GRPC_ADDR" = "0.0.0.0:9301";
        "COLLABORATION_HTTP_ADDR" = "0.0.0.0:9300";
        "COLLABORATION_LOG_LEVEL" = "info";
        "COLLABORATION_WOPI_SRC" = "https://${wopi_uri}";
        "MICRO_REGISTRY" = "nats-js-kv";
        "MICRO_REGISTRY_ADDRESS" = "opencloud:9233";
        "OC_URL" = "https://${opencloud_uri}";
      };
      environmentFiles = [
        config.sops.secrets."opencloud/opencloud/env".path
      ];
      volumes = [
        "${opencloud_config_dir}:/etc/opencloud:rw"
      ];
      ports = [
        "127.0.0.1:${toString wopi_port}:9300/tcp"
      ];
      labels = {
        "compose2nix.settings.sops.secrets" = "opencloud/opencloud/env";
        "io.containers.autoupdate" = "registry";
      };
      cmd = [
        "-c"
        "opencloud collaboration server"
      ];
      dependsOn = [
        "opencloud-collabora"
        "opencloud-opencloud"
      ];
      user = "1000:1000";
      log-driver = "journald";
      extraOptions = [
        "--entrypoint=[\"/bin/sh\"]"
        "--network-alias=collaboration"
        "--network=opencloud_opencloud-net"
      ];
    };
    systemd.services."podman-opencloud-collaboration" = {
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
        "COLLABORA_DOMAIN" = collabora_uri;
        "FRONTEND_APP_HANDLER_SECURE_VIEW_APP_ADDR" = "eu.opencloud.api.collaboration";
        "FRONTEND_ARCHIVER_MAX_SIZE" = "10000000000";
        "FRONTEND_CHECK_FOR_UPDATES" = "true";
        "GATEWAY_GRPC_ADDR" = "0.0.0.0:9142";
        "GRAPH_AVAILABLE_ROLES" =
          "b1e2218d-eef8-4d4c-b82d-0f1a1b48f3b5,a8d5fe5e-96e3-418d-825b-534dbdf22b99,fb6c3e19-e378-47e5-b277-9732f9de6e21,58c63c02-1d89-4572-916a-870abc5a1b7d,2d00ce52-1fc2-4dbc-8b95-a73b73395f5a,1c996275-f1c9-4e71-abdf-a42f6495e960,312c0871-5ef7-4b3a-85b6-0e4074c64049,aa97fe03-7980-45ac-9e50-b325749fd7e6";
        "IDM_CREATE_DEMO_USERS" = "false";
        "NATS_NATS_HOST" = "0.0.0.0";
        "NOTIFICATIONS_SMTP_AUTHENTICATION" = "";
        "NOTIFICATIONS_SMTP_ENCRYPTION" = "none";
        "NOTIFICATIONS_SMTP_HOST" = "";
        "NOTIFICATIONS_SMTP_INSECURE" = "false";
        "NOTIFICATIONS_SMTP_PASSWORD" = "";
        "NOTIFICATIONS_SMTP_PORT" = "";
        "NOTIFICATIONS_SMTP_SENDER" = "OpenCloud Notifications <notifications@cloud.opencloud.test>";
        "NOTIFICATIONS_SMTP_USERNAME" = "";
        "OC_ADD_RUN_SERVICES" = "";
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
        "${opencloud_ref_dir}/config/opencloud/apps:/var/lib/opencloud/web/assets/apps:rw"
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
