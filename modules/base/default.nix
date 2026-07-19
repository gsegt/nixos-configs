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
    enable = lib.mkEnableOption "Whether to enable custom baseline settings.";

    userName = lib.mkOption {
      type = lib.types.str;
      description = "User name of the primary user.";
    };

    groupName = lib.mkOption {
      type = lib.types.str;
      description = "Group name of the primary user.";
    };

    uid = lib.mkOption {
      type = lib.types.int;
      description = "User ID of the primary user.";
    };

    gid = lib.mkOption {
      type = lib.types.int;
      description = "Group ID of the primary user.";
    };

    hostName = lib.mkOption {
      type = lib.types.str;
      description = "Hostname of the current system.";
    };

    timeZone = lib.mkOption {
      type = lib.types.str;
      description = "Timezone of the current system.";
    };
  };

  config = lib.mkIf cfg.enable {
    modules.base = {
      editor.enable = true;
      environment-variables.enable = true;
      home-manager.enable = true;
      nix.enable = true;
      sops.enable = true;
      zram.enable = true;
    };

    environment.systemPackages = with pkgs; [
      git # Necessary for home manager
      nixfmt # For formatting Nix files
    ];

    time.timeZone = cfg.timeZone;

    networking.hostName = cfg.hostName;

    system.stateVersion = "25.05";
  };
}
