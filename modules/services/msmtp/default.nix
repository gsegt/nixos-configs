{ lib, config, ... }:

let
  program = "msmtp";
  cfg = config.modules.services.${program};
in
{
  options.modules.services.${program} = {
    enable = lib.mkEnableOption "Whether to enable custom ${program} settings.";
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."msmtp_default_password" = {
      mode = "444";
    };

    programs.${program} = {
      enable = true;
      accounts.default = {
        auth = true;
        from = "sysadmin@${config.modules.services.reverse-proxy.domain}";
        user = "mail@${config.modules.services.reverse-proxy.domain}";
        host = "ssl0.ovh.net";
        tls = true;
        port = 587;
        passwordeval = "cat ${config.sops.secrets."msmtp_default_password".path}";
      };
    };
  };
}
