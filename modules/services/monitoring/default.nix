{ lib, config, ... }:

let
  utils = import ../../../utils;
  cfg = config.modules.services.monitoring;
in
{
  imports = utils.importSubmodules { dir = ./.; };

  options.modules.services.monitoring = {
    enable = lib.mkEnableOption "Whether to enable custom monitoring settings.";
  };

  config = lib.mkIf cfg.enable {
    modules.services.monitoring = {
      grafana.enable = true;
      prometheus.enable = true;
    };
  };
}
