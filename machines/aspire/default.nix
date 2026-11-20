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
    ipAddress = "192.168.1.253";
    timeZone = "Europe/Paris";
  };

  modules.boot = {
    bootloader.enable = true;
    remote-unlock = {
      enable = true;
      networkKernelModules = [ "r8169" ];
      interface = "enp3s0";
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
    dav = {
      enable = true;
      volumeDir = "${baseServicesDir}/dav";
    };
    drive = {
      enable = true;
      volumeDir = "${baseServicesDir}/drive";
    };
    dyndns-ovh.enable = true;
    file-sync = {
      enable = true;
      volumeDir = "${baseServicesDir}/file-sync";
    };
    home-assistant = {
      enable = true;
      volumeDir = "${baseServicesDir}/home-assistant";
    };
    media-server = {
      enable = true;
      volumeDir = "${baseServicesDir}/media-server";
    };
    monitoring = {
      enable = true;
      volumeDir = "${baseServicesDir}/monitoring";
    };
    msmtp.enable = true;
    notes = {
      enable = true;
      volumeDir = "${baseServicesDir}/notes";
    };
    notifications = {
      enable = true;
      volumeDir = "${baseServicesDir}/notifications";
    };
    password-manager = {
      enable = true;
      volumeDir = "${baseServicesDir}/password-manager";
    };
    photos = {
      enable = true;
      volumeDir = "${baseServicesDir}/photos";
    };
    recipes = {
      enable = true;
      volumeDir = "${baseServicesDir}/recipes";
    };
    reverse-proxy.enable = true;
    valheim = {
      enable = true;
      volumeDir = "${baseServicesDir}/valheim";
    };
  };

  modules.storage.zfs = {
    enable = true;
    mounts = {
      "/media/external/data-vault" = "data-vault";
      "/media/external/data-vault/private" = "data-vault/private";
      ${baseServicesDir} = "data-vault/services";
    };
    smbShares = {
      data_vault_private = "/media/external/data-vault/private";
      data_vault_services = baseServicesDir;
    };
  };

  services.logind.settings.Login.HandleLidSwitch = "ignore";

  hardware.nvidiaOptimus.disable = true;

  nixpkgs.config.allowUnfree = true;
}
