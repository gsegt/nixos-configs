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
      flaresolverr.enable = true;
      prowlarr.enable = true;
    };
  };
}
