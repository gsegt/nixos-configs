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
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = {
        userName = config.modules.base.userName;
      };
      users.${config.modules.base.userName} =
        import ../../../machines/${config.modules.base.hostName}/home.nix;
    };
  };
}
