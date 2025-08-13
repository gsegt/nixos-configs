{
  lib,
  config,
  ...
}:

let
  cfg = config.system.containerisation;
in
{
  options.system.containerisation = {
    enable = lib.mkEnableOption "Enable custom containerisation settings.";
  };

  config = lib.mkIf cfg.enable {
    # Used instead of users.users.<myuser>.extraGroups = [ "docker" ]; to maintain modularity
    users.extraGroups.docker.members = [ config.system.common.username ];

    virtualisation.docker.enable = true;
  };
}
