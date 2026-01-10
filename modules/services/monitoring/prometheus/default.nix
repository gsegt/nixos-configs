{ lib, config, ... }:

let
  service = "prometheus";
  cfg = config.modules.services.monitoring.${service};
in
{
  options.modules.services.monitoring.${service} = {
    enable = lib.mkEnableOption "Whether to enable custom ${service} settings.";
  };

  config = lib.mkIf cfg.enable {
    services.${service} = {
      enable = true;
      exporters.node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
      };
      scrapeConfigs = [
        {
          job_name = "aspire";
          static_configs = [
            {
              targets = [ "127.0.0.1:${toString config.services.${service}.exporters.node.port}" ];
            }
          ];
        }
      ];
    };
  };
}
