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

  systemd.tmpfiles.rules = [
    "d ${baseServicesDir} 0755 ${config.modules.base.userName} ${config.modules.base.groupName} - -"
  ];

  modules.base = {
    enable = true;
    userName = "gsegt";
    groupName = config.modules.base.userName;
    uid = 1000;
    gid = config.modules.base.uid;
    hostName = "aspire";
    timeZone = "Europe/Paris";
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
    dyndns-ovh.enable = true;
    immich = {
      enable = true;
      volumeDir = "${baseServicesDir}/immich";
    };
    joplin = {
      enable = true;
      volumeDir = "${baseServicesDir}/joplin";
    };
    mealie = {
      enable = true;
      volumeDir = "${baseServicesDir}/mealie";
    };
    media-server = {
      enable = true;
      volumeDir = "${baseServicesDir}/media-server";
      torrentingPort = 47563;
    };
    msmtp.enable = true;
    opencloud = {
      enable = true;
      volumeDir = "${baseServicesDir}/opencloud";
    };
    radicale = {
      enable = true;
      volumeDir = "${baseServicesDir}/radicale";
    };
    reverse-proxy.enable = true;
    vaultwarden = {
      enable = true;
      volumeDir = "${baseServicesDir}/vaultwarden";
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
