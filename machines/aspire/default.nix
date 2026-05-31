{ config, ... }:

let
  baseServicesDir = "/media/external/data-vault/services";
in
{
  imports = [
    ./hardware-configuration.nix
    ./video-hardware-acceleration.nix
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
      enable = false;
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
    collabora-online.enable = false;
    dyndns-ovh.enable = true;
    immich = {
      enable = true;
      mediaDir = "${baseServicesDir}/immich";
    };
    joplin = {
      enable = true;
      volumeDir = "${baseServicesDir}/joplin";
    };
    mealie.enable = true;
    media-server = {
      enable = true;
      baseDir = "${baseServicesDir}/media-server";
      subnetWhitelist = "192.168.1.0/24";
      torrentingPort = 47563;
    };
    msmtp.enable = true;
    opencloud = {
      enable = true;
      stateDir = "${baseServicesDir}/opencloud";
    };
    radicale.enable = true;
    reverse-proxy.enable = true;
    vaultwarden = {
      enable = true;
      backupDir = "${baseServicesDir}/vaultwarden";
    };
  };

  modules.storage.zfs = {
    enable = true;
    extraPools = [ "data-vault" ];
  };

  services.logind.settings.Login.HandleLidSwitch = "ignore";

  hardware.nvidiaOptimus.disable = true;

  nixpkgs.config.allowUnfree = true;
}
