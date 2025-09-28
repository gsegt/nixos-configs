{
  lib,
  config,
  pkgs,
  ...
}:

let
  service = "ocis";
  cfg = config.modules.services.${service};
in
{
  options.modules.services.${service} = {
    enable = lib.mkEnableOption "Whether to enable custom ${service} settings.";

    stateDir = lib.mkOption {
      type = lib.types.path;
    };
  };
  config = lib.mkIf cfg.enable {
    services.${service} = {
      enable = true;
      stateDir = "${cfg.stateDir}";
      url = "https://${service}.${config.modules.services.reverse-proxy.domain}";
      environment = {
        PROXY_TLS = "false";
        OCIS_INSECURE = "true";
      };
    };

    systemd.services.${service}.preStart = ''
      ${lib.getExe pkgs.${service}} init || true
    '';

    systemd.tmpfiles.rules = [
      "d ${cfg.stateDir} 1755 ${config.services.${service}.user} ${config.services.${service}.group} - -"
    ];

    services.${config.modules.services.reverse-proxy.service} = {
      virtualHosts."${service}.${config.modules.services.reverse-proxy.domain}".extraConfig = ''
        reverse_proxy ${config.services.${service}.address}:${toString config.services.${service}.port}
      '';
    };

    modules.services.dyndns-ovh.subdomains = [ "${service}" ];
  };
}
