{
  pkgs,
  username,
  hostname,
  ...
}:

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

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "changeme";
  };

  services.logind.lidSwitch = "ignore";

  hardware.nvidiaOptimus.disable = true;
}
