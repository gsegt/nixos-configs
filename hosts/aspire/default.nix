{ config, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../system/common
    ../../system/features/boot-remote-unlock
    ../../system/features/bootloader
    ../../system/features/containerisation
    ../../system/features/dns
    ../../system/features/mealie
    ../../system/features/reverse-proxy
    ../../system/features/ssh
    ../../system/features/zfs
  ];

  common.enable = true;
  common.username = "acer";
  common.hostname = "aspire";

  users.users.${config.common.username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "changeme";
  };

  services.logind.lidSwitch = "ignore";

  hardware.nvidiaOptimus.disable = true;

  boot-remote-unlock = {
    enable = true;
    networkKernelModules = [ "r8169" ];
    ip = "192.168.1.252";
    gateway = "192.168.1.254";
    mask = "255.255.255.0";
  };

  bootloader.enable = true;

  containerisation.enable = true;

  dns.enable = true;

  mealie.enable = true;

  reverse-proxy.enable = true;

  ssh.enable = true;

  zfs.enable = true;
  zfs.extraPools = [ "data-vault" ];
}
