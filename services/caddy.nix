{
  services.caddy = {
    enable = true;
    email = "hostmaster@gsegt.eu";
    virtualHosts."immich.gsegt.eu".extraConfig = ''
      reverse_proxy localhost:2283
    '';
    virtualHosts."joplin.gsegt.eu".extraConfig = ''
      reverse_proxy localhost:22300
    '';
    virtualHosts."mealie.gsegt.eu".extraConfig = ''
      reverse_proxy localhost:9925
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
}
