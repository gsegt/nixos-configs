{ lib, config, ... }:

let
  service = "mealie";
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
        ALLOW_SIGNUP = "false";
        TZ = config.time.timeZone;
      };
    };

    services.${config.modules.services.reverse-proxy.service} = {
      virtualHosts."${service}.${config.modules.services.reverse-proxy.domain}".extraConfig = ''
        reverse_proxy localhost:${toString config.services.${service}.port}
      '';
    };

    modules.services.dyndns-ovh.subdomains = [ "${service}" ];
  };
}
