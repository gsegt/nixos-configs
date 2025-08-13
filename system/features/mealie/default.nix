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
  };
}
