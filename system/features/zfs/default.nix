{ lib, config, ... }:

let
  cfg = config.zfs;
in
{
  options.zfs = {
    enable = lib.mkEnableOption "Enable custom ZFS module";
    extraPools = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra ZFS pools to import.";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.supportedFilesystems = [ "zfs" ];
    boot.zfs.forceImportRoot = false;
    boot.zfs.extraPools = cfg.extraPools;

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

    # Ensure nfs support for shared pools
    networking.firewall.allowedTCPPorts = [ 2049 ];

    services.nfs.server.enable = true;
  };
}
