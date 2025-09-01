{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.modules.services.media-server.torrent-downloader;
  wireguard = config.modules.services.media-server.wireguard-netns;
in
{
  options.modules.services.media-server.torrent-downloader = {
    enable = lib.mkEnableOption "Whether to enable custom torrent-downloader settings.";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      vuetorrent
    ];

    services.qbittorrent = {
      enable = true;
      torrentingPort = 47563;
      openFirewall = true;
      user = config.modules.base.userName;
      group = config.modules.base.userName;
      serverConfig = {
        Preferences = {
          WebUI = {
            AlternativeUIEnabled = true;
            RootFolder = "${pkgs.vuetorrent}/share/vuetorrent";
          };
        };
      };
    };

    systemd = lib.mkIf config.modules.services.media-server.wireguard-netns.enable {
      services = {
        qbittorrent = {
          bindsTo = [ "netns@${wireguard.namespace}.service" ];
          requires = [
            "network-online.target"
            "${wireguard.namespace}.service"
          ];
          serviceConfig.NetworkNamespacePath = [ "/var/run/netns/${wireguard.namespace}" ];
        };

        "qbittorrent-proxy" = {
          enable = true;
          description = "Proxy to qBittorrent WebUI in Network Namespace";
          requires = [
            "qbittorrent.service"
            "qbittorrent-proxy.socket"
          ];
          after = [
            "qbittorrent.service"
            "qbittorrent-proxy.socket"
          ];
          unitConfig = {
            JoinsNamespaceOf = "qbittorrent.service";
          };
          serviceConfig = {
            User = config.services.qbittorrent.user;
            Group = config.services.qbittorrent.group;
            ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd --exit-idle-time=5min 127.0.0.1:${toString config.services.qbittorrent.webuiPort}";
            PrivateNetwork = "yes";
          };
        };
      };

      sockets."qbittorrent-proxy" = {
        enable = true;
        description = "Socket for Proxy to qBittorrent WebUI";
        listenStreams = [ "${toString config.services.qbittorrent.webuiPort}" ];
        wantedBy = [ "sockets.target" ];
      };
    };
  };
}
