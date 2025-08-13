{
  lib,
  config,
  home-manager,
  ...
}:

let
  cfg = config.system.common.home-manager;
in
{
  options.system.common.home-manager = {
    enable = lib.mkEnableOption "Enable custom home-manager settings.";
  };

  config = lib.mkIf cfg.enable {
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.extraSpecialArgs = {
      username = config.system.common.username;
    };
    home-manager.users.${config.system.common.username} =
      import ../../../hosts/${config.system.common.hostname}/home.nix;
  };
}
