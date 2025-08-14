{ lib, config, ... }:

let
  cfg = config.modules.networking.ssh;
in
{
  options.modules.networking.ssh = {
    enable = lib.mkEnableOption "Enable custom ssh settings.";

    ignoreIP = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of IP addresses to never ban after failed login attempts.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
      settings.PermitRootLogin = "no";
    };

    services.fail2ban = {
      enable = true;
      ignoreIP = cfg.ignoreIP;
    };
  };
}
