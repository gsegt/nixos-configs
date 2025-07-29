{ config, zfsExtraPools, ... }:

{
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  boot.zfs.extraPools = zfsExtraPools;

  # Sha512 is overkill since there are no security implications but this should be very future proof
  networking.hostId = builtins.substring 0 8 (
    builtins.hashString "sha512" config.networking.hostName
  );

  services.zfs.autoScrub.enable = true;

  systemd.services.zfs-load-keys = {
    description = "Load zfs encryption keys";
    wantedBy = [ "zfs-mount.service" ];
    before = [ "zfs-mount.service" ];
    after = [ "zfs-import.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = [ "/run/current-system/sw/bin/zfs load-key -a" ];
      StandardInput = "tty-force";
    };
  };
}
