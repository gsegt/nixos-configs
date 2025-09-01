{ lib, config, ... }:

let
  utils = import ../../../utils;
  cfg = config.modules.services.media-server;
in
{
  imports = utils.importSubmodules { dir = ./.; };

  options.modules.services.media-server = {
    enable = lib.mkEnableOption "Whether to enable custom media server settings.";
  };

  config = lib.mkIf cfg.enable {
    modules.services.media-server = {
      bazarr.enable = true;
      flaresolverr.enable = true;
      jellyfin.enable = true;
      jellyseerr.enable = true;
      prowlarr.enable = true;
      radarr.enable = true;
      recyclarr.enable = true;
      sonarr.enable = true;
      torrent-downloader.enable = true;
      wireguard-netns.enable = true;
    };
  };
}
