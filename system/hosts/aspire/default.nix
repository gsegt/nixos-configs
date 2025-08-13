{ config, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../common
    ../../features/boot-remote-unlock
    ../../features/bootloader
    ../../features/containerisation
    ../../features/dns
    ../../features/mealie
    ../../features/ssh
    ../../features/zfs
    ../../features/services/caddy

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

  ssh.enable = true;

  zfs.enable = true;
  zfs.extraPools = [ "data-vault" ];
}
