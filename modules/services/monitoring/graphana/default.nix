{ lib, config, ... }:

let
  service = "grafana";
  cfg = config.modules.services.monitoring.${service};
in
{
  options.modules.services.monitoring.${service} = {
    enable = lib.mkEnableOption "Whether to enable custom ${service} settings.";
  };

  config = lib.mkIf cfg.enable {
    services.${service} = {
      enable = true;
      openFirewall = true;
      settings = {
        server = {
          domain = "192.168.1.253";
          http_addr = "192.168.1.253";
          enable_gzip = true;
        };
        analytics.reporting_enabled = false;
      };
    };

    # services.${config.modules.services.reverse-proxy.service} = {
    #   virtualHosts."192.168.1.253:13000".extraConfig = ''
    #     reverse_proxy localhost:${toString config.services.${service}.settings.server.http_port}
    #   '';
    # };
  };
}
