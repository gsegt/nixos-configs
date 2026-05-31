{ lib, config, ... }:

let
  service = "collabora-online";
  cfg = config.modules.services.${service};
in
{
  options.modules.services.${service} = {
    enable = lib.mkEnableOption "Whether to enable custom ${service} settings.";
  };

  config = lib.mkIf cfg.enable {
    services.${service} = {
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
          host = [
            config.modules.services.reverse-proxy.domain
          ];
        };
        server_name = "${service}.${config.modules.services.reverse-proxy.domain}";
      };
    };

    services.${config.modules.services.reverse-proxy.service} = {
      virtualHosts."${config.services.${service}.settings.server_name}".extraConfig = ''
        reverse_proxy [::1]:${toString config.services.${service}.port}
      '';
    };

    modules.services.dyndns-ovh.subdomains = [ service ];
  };
}
