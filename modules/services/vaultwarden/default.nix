{ lib, config, ... }:

let
  service = "vaultwarden";
  port = 8000;
  cfg = config.modules.services.${service};
in
{
  options.modules.services.${service} = {
    enable = lib.mkEnableOption "Whether to enable custom ${service} settings.";

    backupDir = lib.mkOption {
      type = lib.types.path;
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."vaultwarden/env" = {
      owner = service;
      group = service;
    };

    services.${service} = {
      enable = true;
      backupDir = cfg.backupDir;
      config = {
        DOMAIN = "https://${service}.${config.modules.services.reverse-proxy.domain}";
        SIGNUPS_ALLOWED = false;

        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = port;

        SMTP_HOST = config.programs.msmtp.accounts.default.host;
        SMTP_PORT = config.programs.msmtp.accounts.default.port;
        SMTP_SECURITY = "starttls";
        SMTP_USERNAME = config.programs.msmtp.accounts.default.user;
        SMTP_FROM = "${service}@${config.modules.services.reverse-proxy.domain}";
        SMTP_FROM_NAME = "${config.modules.services.reverse-proxy.domain} ${service} server";
      };
      environmentFile = config.sops.secrets."vaultwarden/env".path;
    };

    services.${config.modules.services.reverse-proxy.service} = {
      virtualHosts."${service}.${config.modules.services.reverse-proxy.domain}".extraConfig = ''
          reverse_proxy ${toString config.services.${service}.config.ROCKET_ADDRESS}:${
            toString config.services.${service}.config.ROCKET_PORT
          } {
          header_up X-Real-IP {remote_host}
        }
      '';
    };

    modules.services.dyndns-ovh.subdomains = [ service ];
  };
}
