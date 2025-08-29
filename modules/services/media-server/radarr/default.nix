{ lib, config, ... }:

let
  service = "radarr";
  cfg = config.modules.services.media-server.${service};
in
{
  options.modules.services.media-server.${service} = {
    enable = lib.mkEnableOption "Whether to enable custom ${service} settings.";
  };

  config = lib.mkIf cfg.enable {
    services.${service} = {
      enable = true;
      openFirewall = true;
      user = config.modules.base.userName;
      group = config.modules.base.userName;
    };
  };
}
