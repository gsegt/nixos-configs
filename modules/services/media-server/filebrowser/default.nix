{ lib, config, ... }:

let
  service = "filebrowser";
  port = 8082;
  cfg = config.modules.services.media-server.${service};
in
{
  options.modules.services.media-server.${service} = {
    enable = lib.mkEnableOption "Whether to enable custom ${service} settings.";

    rootDir = lib.mkOption {
      type = lib.types.path;
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${cfg.rootDir} 0755 ${config.services.${service}.user} ${config.services.${service}.group} - -"
    ];

    services.${service} = {
      enable = true;
      openFirewall = true;
      user = config.modules.base.userName;
      group = config.modules.base.userName;
      settings = {
        address = "192.168.1.253";
        port = port;
        root = cfg.rootDir;
      };
    };

    services.${config.modules.services.reverse-proxy.service} = {
      virtualHosts."${service}.${config.modules.services.reverse-proxy.domain}".extraConfig = ''
        reverse_proxy ${config.services.${service}.settings.address}:${
          toString config.services.${service}.settings.port
        } {
        };
      '';
    };

    modules.services.dyndns-ovh.subdomains = [ service ];
  };
}
