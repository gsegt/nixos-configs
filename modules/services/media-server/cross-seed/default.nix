{ lib, config, ... }:

let
  service = "cross-seed";
  cfg = config.modules.services.media-server.${service};
in
{
  options.modules.services.media-server.${service} = {
    enable = lib.mkEnableOption "Whether to enable custom ${service} settings.";
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."cross-seed/settings.json" = { };

    services.${service} = {
      enable = true;
      user = config.modules.base.userName;
      group = config.modules.base.userName;
      settings = {
        dataDirs = [
          "${config.services.qbittorrent.serverConfig.BitTorrent.Session.DefaultSavePath}/sonarr/"
          "${config.services.qbittorrent.serverConfig.BitTorrent.Session.DefaultSavePath}/radarr/"
          "${config.services.qbittorrent.serverConfig.BitTorrent.Session.DefaultSavePath}/prowlarr/"
        ];
        linkDirs = [
          "${config.services.qbittorrent.serverConfig.BitTorrent.Session.DefaultSavePath}/cross-seed/"
        ];
        outputDir = null;
        useGenConfigDefaults = true;
        action = "inject";
        linkType = "hardlink";
        linkCategory = "cross-seed";
        useClientTorrents = true;
        torrentClients = [
          "qbittorrent:http://localhost:${toString config.services.qbittorrent.webuiPort}"
        ];
      };
      settingsFile = config.sops.secrets."cross-seed/settings.json".path;
    };
  };
}
