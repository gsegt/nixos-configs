{ lib, config, ... }:

let
  utils = import ../../../utils;
  cfg = config.modules.services.media-server;
in
{
  imports = utils.importSubmodules { dir = ./.; };

  options.modules.services.media-server = {
    enable = lib.mkEnableOption "Whether to enable custom media server settings.";

    baseDir = lib.mkOption {
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
      "d ${cfg.baseDir} 0755 ${config.modules.base.userName} ${config.modules.base.userName} - -"
    ];

    modules.services.media-server = {
      bazarr.enable = true;
      clonarr = {
        enable = true;
        volumeDir = "${cfg.baseDir}/clonarr";
      };
      filebrowser = {
        enable = true;
        rootDir = "${cfg.baseDir}/media";
      };
      flaresolverr.enable = true;
      jellyfin.enable = true;
      jellyseerr.enable = true;
      prowlarr.enable = true;
      radarr.enable = true;
      sonarr.enable = true;
      torrent-downloader = {
        enable = true;
        savePath = "${cfg.baseDir}/torrents";
        subnetWhitelist = cfg.subnetWhitelist;
        torrentingPort = cfg.torrentingPort;
      };
      wireguard-netns.enable = true;
    };
  };
}
