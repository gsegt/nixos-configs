{
  lib,
  config,
  ...
}:

let
  cfg = config.system.bootloader;
in
{
  options.system.bootloader = {
    enable = lib.mkEnableOption "Enable custom bootloader settings.";
  };

  config = lib.mkIf cfg.enable {
    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };
}
