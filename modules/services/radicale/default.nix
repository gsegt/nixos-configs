{ lib, config, ... }:

let
  service = "radicale";
  cfg = config.modules.services.${service};
in
{
  options.modules.services.${service} = {
    enable = lib.mkEnableOption "Whether to enable custom ${service} settings.";

    port = lib.mkOption {
      type = lib.types.port;
      default = 5232;
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."radicale/htpasswd" = {
      owner = "${service}";
      group = "${service}";
    };

    services.${service} = {
      enable = true;
      settings = {
        server = {
          hosts = [
            "localhost:${toString cfg.port}"
          ];
        };

        auth = {
          type = "htpasswd";
          htpasswd_filename = config.sops.secrets."radicale/htpasswd".path;
          htpasswd_encryption = "autodetect";
        };
      };
    };

    services.${config.modules.services.reverse-proxy.service} = {
      virtualHosts."${service}.${config.modules.services.reverse-proxy.domain}".extraConfig = ''
        reverse_proxy ${builtins.head config.services.radicale.settings.server.hosts} {
          header_up X-Remote-User {http.auth.user.id}
        }
      '';
    };

    modules.services.dyndns-ovh.subdomains = [ "${service}" ];
  };
}
