{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.system.common;
in
{
  imports = [
    ./editor
    ./environment-variables
    ./home-manager
    ./nix
    ./user
    ./zram
  ];

  options.system.common = {
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

  config = lib.mkIf cfg.enable {
    system.common.editor.enable = true;

    system.common.environment-variables.enable = true;

    system.common.home-manager.enable = true;

    system.common.nix.enable = true;

    system.common.user.enable = true;

    system.common.zram.enable = true;

    environment.systemPackages = with pkgs; [
      git # Necessary for home manager
      nixfmt-rfc-style # For formatting Nix files
    ];

    time.timeZone = cfg.timeZone;

    networking.hostName = cfg.hostname;

    system.stateVersion = "25.05";
  };
}
