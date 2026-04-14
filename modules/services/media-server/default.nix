{ lib, config, ... }:

let
  utils = import ../../../utils;
  baseVolumeDir = "/media/external/data-vault/services/media-server";
  cfg = config.modules.services.media-server;
in
{
  imports = utils.importSubmodules { dir = ./.; };

  options.modules.services.media-server = {
    enable = lib.mkEnableOption "Whether to enable custom media server settings.";

    savePath = lib.mkOption {
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
      "d ${baseVolumeDir} 0755 root root - -"
    ];

    modules.services.media-server = {
      bazarr.enable = true;
      clonarr = {
        enable = true;
        volumeDir = "${baseVolumeDir}/clonarr";
      };
      flaresolverr.enable = true;
      jellyfin.enable = true;
      jellyseerr.enable = true;
      prowlarr.enable = true;
      radarr.enable = true;
      sonarr.enable = true;
      torrent-downloader = {
        enable = true;
        savePath = cfg.savePath;
        subnetWhitelist = cfg.subnetWhitelist;
        torrentingPort = cfg.torrentingPort;
      };
      wireguard-netns.enable = true;
      ygege.enable = true;
    };
  };
}
