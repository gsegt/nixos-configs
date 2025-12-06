{ lib, config, ... }:

let
  service = "jellyfin";
  cfg = config.modules.services.media-server.${service};
in
{
  options.modules.services.media-server.${service} = {
    enable = lib.mkEnableOption "Whether to enable custom ${service} settings.";
  };

  config = lib.mkIf cfg.enable {
    services.${service} = {
      enable = true;
      openFirewall = true;
      user = config.modules.base.userName;
      group = config.modules.base.userName;
    };

    services.${config.modules.services.reverse-proxy.service} = {
      virtualHosts."${service}.${config.modules.services.reverse-proxy.domain}".extraConfig = ''
        reverse_proxy localhost:8096
      '';
    };

    modules.services.dyndns-ovh.subdomains = [ "${service}" ];
  };
}
