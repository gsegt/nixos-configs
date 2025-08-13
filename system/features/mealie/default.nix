{
  lib,
  config,
  ...
}:

let
  cfg = config.mealie;
in
{
  options.mealie = {
    enable = lib.mkEnableOption "Whether to enable custom Mealie settings.";
    port = lib.mkOption {
      type = lib.types.port;
      default = 9000;
      description = "Port on which to serve the Mealie service.";
    };
    url = lib.mkOption {
      type = lib.types.str;
      default = "mealie.gsegt.eu";
    };
  };

  config = lib.mkIf cfg.enable {
    services.mealie = {
      enable = true;
      port = cfg.port;
      settings = {
        ALLOW_SIGNUP = "false";
        TZ = config.time.timeZone;
      };
    };

    services.caddy.virtualHosts."${cfg.url}".extraConfig = ''
      reverse_proxy localhost:${toString cfg.port}
    '';
  };
}
