{
  lib,
  config,
  ...
}:

let
  cfg = config.reverse-proxy;
in
{
  options.reverse-proxy = {
    enable = lib.mkEnableOption "Enable custom reverse-proxy settings.";
  };

  config = lib.mkIf cfg.enable {
    services.caddy = {
      enable = true;
      email = "hostmaster@gsegt.eu";
      virtualHosts."immich.gsegt.eu".extraConfig = ''
        reverse_proxy localhost:2283
      '';
      virtualHosts."joplin.gsegt.eu".extraConfig = ''
        reverse_proxy localhost:22300
      '';
      virtualHosts."jellyfin.gsegt.eu".extraConfig = ''
        reverse_proxy localhost:8096
      '';
      virtualHosts."jellyseerr.gsegt.eu".extraConfig = ''
        reverse_proxy localhost:5055
      '';
      virtualHosts."nextcloud.gsegt.eu".extraConfig = ''
        redir /.well-known/carddav /remote.php/dav/ 301
        redir /.well-known/caldav /remote.php/dav/ 301
        reverse_proxy localhost:8888
      '';
    };

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
  };
}
