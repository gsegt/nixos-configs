{
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  boot.zfs.extraPools = [ "data_vault" ];

  networking.hostId = "228b6aee";

  services.zfs.autoScrub.enable = true;
}
