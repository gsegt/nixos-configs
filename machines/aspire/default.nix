{ config, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules
  ];

  modules.base.enable = true;
  modules.base.username = "acer";
  modules.base.hostname = "aspire";

  modules.boot.bootloader.enable = true;

  modules.boot.remote-unlock = {
    enable = true;
    networkKernelModules = [ "r8169" ];
    ip = "192.168.1.252";
    gateway = "192.168.1.254";
    mask = "255.255.255.0";
  };

  modules.containers.enable = true;

  modules.networking.dns.enable = true;
  modules.networking.ssh.enable = true;

  modules.services.mealie.enable = true;
  modules.services.reverse-proxy.enable = true;

  modules.storage.zfs.enable = true;
  modules.storage.zfs.extraPools = [ "data-vault" ];

  users.users.${config.modules.base.username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "changeme";
  };

  services.logind.lidSwitch = "ignore";

  hardware.nvidiaOptimus.disable = true;
}
