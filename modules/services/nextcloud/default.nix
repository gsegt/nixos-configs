{
  lib,
  config,
  pkgs,
  ...
}:

let
  service = "nextcloud";
  cfg = config.modules.services.${service};
in
{
  options.modules.services.${service} = {
    enable = lib.mkEnableOption "Whether to enable custom ${service} settings.";

    dataDir = lib.mkOption {
      type = lib.types.path;
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8081;
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."nextcloud_admin_password" = {
      owner = "${service}";
      group = "${service}";
    };

    services.${service} = {
      enable = true;
      package = pkgs.nextcloud32;
      https = true;
      hostName = "${service}.${config.modules.services.reverse-proxy.domain}";
      datadir = "${cfg.dataDir}";
      database.createLocally = true;
      config = {
        adminuser = "gsegt";
        adminpassFile = config.sops.secrets."nextcloud_admin_password".path;
        dbtype = "pgsql";
      };
      settings = {
        mail_smtpmode = "sendmail";
        mail_sendmailmode = "pipe";
        mail_from_address = "nextcloud";
        mail_domain = config.modules.services.reverse-proxy.domain;
        default_phone_region = "FR";
        trusted_proxies = [ "127.0.0.1" ];
        enabledPreviewProviders = [
          "OC\\Preview\\BMP"
          "OC\\Preview\\GIF"
          "OC\\Preview\\HEIC"
          "OC\\Preview\\JPEG"
          "OC\\Preview\\Krita"
          "OC\\Preview\\MarkDown"
          "OC\\Preview\\MP3"
          "OC\\Preview\\OpenDocument"
          "OC\\Preview\\PNG"
          "OC\\Preview\\TXT"
          "OC\\Preview\\WebP"
          "OC\\Preview\\XBitmap"
        ];
      };
      extraAppsEnable = true;
      autoUpdateApps.enable = true;
      extraApps = {
        inherit (config.services.${service}.package.packages.apps)
          richdocuments
          ;
      };
    };

    services.nginx.virtualHosts."${config.services.${service}.hostName}".listen = [
      {
        addr = "127.0.0.1";
        port = cfg.port;
      }
    ];

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 1755 ${service} ${service} - -"
    ];

    services.collabora-online = {
      enable = true;
      settings = {
        ssl = {
          enable = false;
          termination = true;
        };
        net = {
          listen = "loopback";
          post_allow.host = [ "[::1]" ];
        };
        storage.wopi = {
          "@allow" = true;
          host = [ "${config.services.${service}.hostName}" ];
        };
        server_name = "collabora.${config.modules.services.reverse-proxy.domain}";
      };
    };

    # This is a workaround to avoid having to add collabora-online to the hosts file on every machine that needs to access it, since collabora-online is only listening on loopback and the reverse proxy is forwarding requests to it.
    # Proper solution would be to add public ip to wopi_allowlist
    networking.hosts = {
      "127.0.0.1" = [
        config.services.collabora-online.settings.server_name
        config.services.${service}.hostName
      ];
      "::1" = [
        config.services.collabora-online.settings.server_name
        config.services.${service}.hostName
      ];
    };

    systemd.services = {
      "${service}-custom-config" = {
        path = [
          config.services.${service}.occ
        ];
        script = ''
          nextcloud-occ app:disable activity
          nextcloud-occ app:disable admin_audit
          nextcloud-occ app:disable app_api
          nextcloud-occ app:disable circles
          nextcloud-occ app:disable comments
          nextcloud-occ app:disable contactsinteraction
          nextcloud-occ app:disable dashboard
          nextcloud-occ app:disable encryption
          nextcloud-occ app:disable federation
          nextcloud-occ app:disable files_external
          nextcloud-occ app:disable firstrunwizard
          nextcloud-occ app:disable nextcloud_announcements
          nextcloud-occ app:disable photos
          nextcloud-occ app:disable support
          nextcloud-occ app:disable survey_client
          nextcloud-occ app:disable suspicious_login
          nextcloud-occ app:disable systemtags
          nextcloud-occ app:disable twofactor_nextcloud_notification
          nextcloud-occ app:disable twofactor_totp
          nextcloud-occ app:disable user_ldap
          nextcloud-occ app:disable user_status
          nextcloud-occ app:disable weather_status
          nextcloud-occ app:disable webhook_listeners
          nextcloud-occ config:system:set maintenance_window_start --value=1 --type=integer
        '';
        after = [ "nextcloud-setup.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
        };
      };

      "nextcloud-collabora-config" =
        let
          wopi_url = "http://[::1]:${toString config.services.collabora-online.port}";
          public_wopi_url = "https://${config.services.collabora-online.settings.server_name}";
          wopi_allowlist = lib.concatStringsSep "," [
            "127.0.0.1"
            "::1"
          ];
        in
        {
          path = [
            config.services.${service}.occ
          ];
          script = ''
            nextcloud-occ config:app:set richdocuments wopi_url --value ${lib.escapeShellArg wopi_url}
            nextcloud-occ config:app:set richdocuments public_wopi_url --value ${lib.escapeShellArg public_wopi_url}
            nextcloud-occ config:app:set richdocuments wopi_allowlist --value ${lib.escapeShellArg wopi_allowlist}
            nextcloud-occ richdocuments:setup
          '';
          requires = [ "coolwsd.service" ];
          after = [
            "nextcloud-setup.service"
            "coolwsd.service"
          ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
          };
        };
    };

    services.${config.modules.services.reverse-proxy.service} = {
      virtualHosts."${config.services.${service}.hostName}".extraConfig = ''
        header {
          Strict-Transport-Security "max-age=31536000; includeSubDomains"
        }

        redir /.well-known/carddav /remote.php/dav/ 301
        redir /.well-known/caldav /remote.php/dav/ 301

        reverse_proxy localhost:${toString cfg.port}
      '';

      virtualHosts."${config.services.collabora-online.settings.server_name}".extraConfig = ''
        reverse_proxy [::1]:${toString config.services.collabora-online.port}
      '';
    };

    modules.services.dyndns-ovh.subdomains = [
      "${service}"
      "collabora"
    ];
  };
}
