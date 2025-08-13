{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.system.common.user;
in
{
  options.system.common.user = {
    enable = lib.mkEnableOption "Enable common user settings for all systems";
  };

  config = lib.mkIf cfg.enable {
    users.users.${config.system.common.username} = {
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDwPeKHdo/JDZ4TsrOVzgY2mEjTi1vL6UZzJ4ulaJpaY"
      ];
      shell = pkgs.fish;
    };

    security.sudo.wheelNeedsPassword = false; # Technically redundant for wsl systems

    programs.fish.enable = true; # Needs to be installed system wide for user to login
  };
}
