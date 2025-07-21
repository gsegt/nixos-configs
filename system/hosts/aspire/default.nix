{
  pkgs,
  username,
  hostname,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../common.nix
    ../../features/bootloader.nix
    ../../features/dns.nix
    ../../features/docker.nix
    ../../features/nfs.nix
    ../../features/remote-unlock.nix
    ../../features/samba.nix
    ../../features/ssh.nix
    ../../features/timezone.nix
    ../../features/zfs.nix
    ../../features/services/caddy.nix
    ../../features/services/mealie.nix
  ];

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "changeme";
  };

  security.sudo.extraRules = [
    {
      users = [ username ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  services.logind.lidSwitch = "ignore";

  hardware.nvidiaOptimus.disable = true;
}
