{
  lib,
  config,
  ...
}:

let
  cfg = config.containerisation;
in
{
  options.containerisation = {
    enable = lib.mkEnableOption "Enable custom containerisation settings.";
  };

  config = lib.mkIf cfg.enable {
    # Used instead of users.users.<myuser>.extraGroups = [ "docker" ]; to maintain modularity
    users.extraGroups.docker.members = [ config.common.username ];

    virtualisation.docker.enable = true;
  };
}
