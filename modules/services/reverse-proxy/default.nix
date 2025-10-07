{ lib, config, ... }:

let
  cfg = config.modules.services.reverse-proxy;
in
{
  options.modules.services.reverse-proxy = {
    enable = lib.mkEnableOption "Whether to enable custom reverse-proxy settings.";

    domain = lib.mkOption {
      type = lib.types.str;
      default = "gsegt.eu";
    };

    service = lib.mkOption {
      type = lib.types.str;
      default = "caddy";
      description = "The reverse proxy service to use (e.g., caddy, nginx).";
    };
  };

  config = lib.mkIf cfg.enable {
    services.${cfg.service} = {
      enable = true;
      email = "hostmaster@${cfg.domain}";
      virtualHosts."joplin.gsegt.eu".extraConfig = ''
        reverse_proxy localhost:22300
      '';
    };

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];

    modules.services.dyndns-ovh.subdomains = [
      "joplin"
    ];
  };
}
