{ lib, config, ... }:

let
  utils = import ../../../utils;
  cfg = config.modules.services.media-server;
in
{
  imports = utils.importSubmodules { dir = ./.; };

  options.modules.services.media-server = {
    enable = lib.mkEnableOption "Whether to enable custom media server settings.";

    baseSavePath = lib.mkOption {
      type = lib.types.path;
    };

    baseVolumeDir = lib.mkOption {
      type = lib.types.path;
    };

    subnetWhitelist = lib.mkOption {
      type = lib.types.str;
    };

    torrentingPort = lib.mkOption {
      type = lib.types.int;
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${cfg.baseVolumeDir} 0755 root root - -"
    ];

    modules.services.media-server = {
      bazarr.enable = true;
      clonarr = {
        enable = true;
        volumeDir = "${cfg.baseVolumeDir}/clonarr";
      };
      filebrowser = {
        enable = true;
        rootDir = "${cfg.baseSavePath}/media";
      };
      flaresolverr.enable = true;
      jellyfin.enable = true;
      jellyseerr.enable = true;
      prowlarr.enable = true;
      radarr.enable = true;
      sonarr.enable = true;
      qui = {
        enable = true;
        volumeDir = "${cfg.baseVolumeDir}/qui";
        qbittorrentSavePath = "${cfg.baseSavePath}/torrents";
      };
      torrent-downloader = {
        enable = true;
        savePath = "${cfg.baseSavePath}/torrents";
        subnetWhitelist = cfg.subnetWhitelist;
        torrentingPort = cfg.torrentingPort;
      };
      wireguard-netns.enable = true;
    };
  };
}
