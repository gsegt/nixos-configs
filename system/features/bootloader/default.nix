{
  lib,
  config,
  ...
}:

let
  cfg = config.bootloader;
in
{
  options.bootloader = {
    enable = lib.mkEnableOption "Enable custom bootloader settings.";
  };

  config = lib.mkIf cfg.enable {
    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };
}
