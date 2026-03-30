{ lib, config, ... }:

let
  service = "paperless";
  cfg = config.modules.services.${service};
in
{
  options.modules.services.${service} = {
    enable = lib.mkEnableOption "Whether to enable custom ${service} settings.";

    mediaDir = lib.mkOption {
      type = lib.types.path;
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."paperless_admin_password" = {
      owner = config.services.${service}.user;
      group = config.services.${service}.user;
    };

    services.${service} = {
      enable = true;
      passwordFile = config.sops.secrets."paperless_admin_password".path;
      domain = "${service}.${config.modules.services.reverse-proxy.domain}";
      mediaDir = "${cfg.mediaDir}";
      database.createLocally = true;
      configureTika = true;
      settings = {
        PAPERLESS_OCR_LANGUAGE = "eng+fra";
      };
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.mediaDir} 1755 ${config.services.${service}.user} ${config.services.${service}.user} - -"
    ];

    services.${config.modules.services.reverse-proxy.service} = {
      virtualHosts."${config.services.${service}.domain}".extraConfig = ''
        reverse_proxy localhost:${toString config.services.${service}.port}
      '';
    };

    modules.services.dyndns-ovh.subdomains = [ "${service}" ];
  };
}
