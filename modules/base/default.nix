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

    userName = lib.mkOption {
      type = lib.types.str;
      description = "Username of the primary user";
    };

    hostName = lib.mkOption {
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
    modules.base = {
      editor.enable = true;
      environment-variables.enable = true;
      home-manager.enable = true;
      nix.enable = true;
      zram.enable = true;
    };

    environment.systemPackages = with pkgs; [
      git # Necessary for home manager
      nixfmt-rfc-style # For formatting Nix files
    ];

    time.timeZone = cfg.timeZone;

    networking.hostName = cfg.hostName;

    system.stateVersion = "25.05";
  };
}
