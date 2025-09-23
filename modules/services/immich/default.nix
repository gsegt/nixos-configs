{ lib, config, ... }:

let
  service = "immich";
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
    services.${service} = {
      enable = true;
      openFirewall = true;
      mediaLocation = "${cfg.mediaDir}";
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.mediaDir} 0755 ${config.services.${service}.user} ${config.services.${service}.group} - -"
    ];

    users.users.${config.services.${service}.user}.extraGroups = [
      "video"
      "render"
    ];

    systemd.services.immich-machine-learning.environment.LIBVA_DRIVER_NAME = "iHD";

    services.${config.modules.services.reverse-proxy.service} = {
      virtualHosts."${service}.${config.modules.services.reverse-proxy.domain}".extraConfig = ''
        reverse_proxy localhost:${toString config.services.${service}.port}
      '';
    };

    modules.services.dyndns-ovh.subdomains = [ "${service}" ];
  };

}
