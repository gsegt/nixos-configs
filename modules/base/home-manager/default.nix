{
  lib,
  config,
  pkgs,
  home-manager,
  ...
}:

let
  cfg = config.modules.base.home-manager;
in
{
  options.modules.base.home-manager = {
    enable = lib.mkEnableOption "Whether to enable custom home-manager settings.";
  };

  config = lib.mkIf cfg.enable {
    users = {
      users.${config.modules.base.userName} = {
        isNormalUser = true;
        uid = 1000;
        group = config.modules.base.userName;
        extraGroups = [
          "users"
          "wheel"
        ];
        initialPassword = "changeme";
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDwPeKHdo/JDZ4TsrOVzgY2mEjTi1vL6UZzJ4ulaJpaY"
        ];
        shell = pkgs.fish;
      };
      groups = {
        ${config.modules.base.userName} = {
          gid = 1000;
        };
      };
    };

    security.sudo.wheelNeedsPassword = false;

    programs.fish.enable = true; # Needs to be installed system wide for user to login

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = {
        userName = config.modules.base.userName;
      };
      users.${config.modules.base.userName} = import ../../../users/${config.modules.base.userName};
    };
  };
}
