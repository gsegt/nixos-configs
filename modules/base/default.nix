{
  lib,
  config,
  pkgs,
  ...
}:

let
  utils = import ../../utils;
  cfg = config.modules.base;
in
{
  imports = utils.importSubmodules { dir = ./.; };

  options.modules.base = {
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
    modules.base.editor.enable = true;

    modules.base.environment-variables.enable = true;

    modules.base.home-manager.enable = true;

    modules.base.nix.enable = true;

    modules.base.user.enable = true;

    modules.base.zram.enable = true;

    environment.systemPackages = with pkgs; [
      git # Necessary for home manager
      nixfmt-rfc-style # For formatting Nix files
    ];

    time.timeZone = cfg.timeZone;

    networking.hostName = cfg.hostname;

    system.stateVersion = "25.05";
  };
}
