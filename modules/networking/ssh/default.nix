{ lib, config, ... }:

let
  cfg = config.modules.networking.ssh;
in
{
  options.modules.networking.ssh = {
    enable = lib.mkEnableOption "Enable custom ssh settings.";
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
      settings.PermitRootLogin = "no";
    };

    services.fail2ban.enable = true;
  };
}
