{ config, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../common
    ../../features/bootloader
    ../../features/dns
    ../../features/docker
    ../../features/nfs
    ../../features/remote-unlock
    ../../features/samba
    ../../features/ssh
    ../../features/timezone
    ../../features/zfs
    ../../features/services/caddy
    ../../features/services/mealie
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
}
