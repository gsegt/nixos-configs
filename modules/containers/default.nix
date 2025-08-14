{ lib, config, ... }:

let
  cfg = config.modules.containers;
in
{
  options.modules.containers = {
    enable = lib.mkEnableOption "Enable custom containerisation settings.";
  };

  config = lib.mkIf cfg.enable {
    # Used instead of users.users.<myuser>.extraGroups = [ "docker" ]; to maintain modularity
    users.extraGroups.docker.members = [ config.modules.base.userName ];

    virtualisation.docker.enable = true;
  };
}
