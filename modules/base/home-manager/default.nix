{
  lib,
  config,
  home-manager,
  ...
}:

let
  cfg = config.modules.base.home-manager;
in
{
  options.modules.base.home-manager = {
    enable = lib.mkEnableOption "Enable custom home-manager settings.";
  };

  config = lib.mkIf cfg.enable {
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.extraSpecialArgs = {
      username = config.modules.base.username;
    };
    home-manager.users.${config.modules.base.username} =
      import ../../../machines/${config.modules.base.hostname}/home.nix;
  };
}
