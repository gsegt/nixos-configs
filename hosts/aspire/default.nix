{ config, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../system
  ];

  system.common.enable = true;
  system.common.username = "acer";
  system.common.hostname = "aspire";

  users.users.${config.system.common.username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "changeme";
  };

  services.logind.lidSwitch = "ignore";

  hardware.nvidiaOptimus.disable = true;

  system.boot-remote-unlock = {
    enable = true;
    networkKernelModules = [ "r8169" ];
    ip = "192.168.1.252";
    gateway = "192.168.1.254";
    mask = "255.255.255.0";
  };

  system.bootloader.enable = true;

  system.containerisation.enable = true;

  system.dns.enable = true;

  system.services.mealie.enable = true;

  system.services.reverse-proxy.enable = true;

  system.ssh.enable = true;

  system.zfs.enable = true;
  system.zfs.extraPools = [ "data-vault" ];
}
