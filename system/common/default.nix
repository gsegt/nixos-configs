{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.common;
in
{
  options.common = {
    enable = lib.mkEnableOption "Enable common settings for all systems";
    username = lib.mkOption {
      type = lib.types.str;
      default = "gsegt";
      description = "Username of the primary user";
    };
    hostname = lib.mkOption {
      type = lib.types.str;
      description = "Hostname of the current system";
    };
    timeZone = lib.mkOption {
      type = lib.types.str;
      default = "Europe/Paris";
      description = "Timezone of the current system";
    };
  };

  imports = [
    ./editor
    ./environment-variables
    ./nix
    ./user
    ./zram
  ];

  config = lib.mkIf cfg.enable {
    common.zram.enable = true;

    environment.systemPackages = with pkgs; [
      git # Necessary for home manager
      nixfmt-rfc-style # For formatting Nix files
    ];

    time.timeZone = cfg.timeZone;

    networking.hostName = cfg.hostname;

    system.stateVersion = "25.05";
  };
}
