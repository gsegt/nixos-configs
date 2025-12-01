{ config, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./qsv-hardware-acceleration.nix
    ../../modules
  ];

  modules.base = {
    enable = true;
    userName = "gsegt";
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
    ssh = {
      enable = true;
      ignoreIP = [ "192.168.1.0/24" ];
    };
  };

  modules.services = {
    dyndns-ovh.enable = true;
    immich = {
      enable = true;
      mediaDir = "/media/external/data-vault/services/immich";
    };
    joplin = {
      enable = true;
      volumeDir = "/media/external/data-vault/services/joplin";
    };
    mealie.enable = true;
    media-server.enable = true;
    ocis = {
      enable = true;
      stateDir = "/media/external/data-vault/services/ocis";
    };
    radicale.enable = true;
    reverse-proxy.enable = true;
  };

  modules.storage.zfs = {
    enable = true;
    extraPools = [ "data-vault" ];
  };

  services.logind.settings.Login.HandleLidSwitch = "ignore";

  hardware.nvidiaOptimus.disable = true;

  nixpkgs.config.allowUnfree = true;
}
