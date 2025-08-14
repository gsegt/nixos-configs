{ config, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules
  ];

  modules.base = {
    enable = true;
    userName = "acer";
    hostName = "aspire";
  };

  modules.boot = {
    bootloader.enable = true;
    remote-unlock = {
      enable = true;
      networkKernelModules = [ "r8169" ];
      ip = "192.168.1.252";
      gateway = "192.168.1.254";
      mask = "255.255.255.0";
    };
  };

  modules.containers.enable = true;

  modules.networking = {
    dns.enable = true;
    ssh.enable = true;
  };

  modules.services = {
    mealie.enable = true;
    reverse-proxy.enable = true;
  };

  modules.storage.zfs = {
    enable = true;
    extraPools = [ "data-vault" ];
  };

  users.users.${config.modules.base.userName} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "changeme";
  };

  services.logind.lidSwitch = "ignore";

  hardware.nvidiaOptimus.disable = true;
}
