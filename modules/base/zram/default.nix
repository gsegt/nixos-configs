{
  lib,
  config,
  ...
}:

let
  cfg = config.modules.base.zram;
in
{
  options.modules.base.zram = {
    enable = lib.mkEnableOption "Enable common zRAM settings for all systems";

  };
  config = lib.mkIf cfg.enable {
    # Recommendations from https://wiki.archlinux.org/title/Zram#Optimizing_swap_on_zram
    boot.kernel.sysctl = {
      "vm.swappiness" = 180;
      "vm.watermark_boost_factor" = 0;
      "vm.watermark_scale_factor" = 125;
      "vm.page-cluster" = 0;
    };

    zramSwap = {
      enable = true;
      memoryPercent = 100;
    };
  };
}
