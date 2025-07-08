{
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  boot.zfs.extraPools = [ "data-vault" ];

  networking.hostId = "228b6aee";

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
