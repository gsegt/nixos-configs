{ lib, config, ... }:

let
  cfg = config.modules.storage.zfs;
in
{
  options.modules.storage.zfs = {
    enable = lib.mkEnableOption "Whether to enable custom ZFS settings.";

    extraPools = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Name or GUID of extra ZFS pools that you wish to import during boot.
        Only needed for pools with no dataset in `mounts`: those are imported
        automatically.
      '';
    };

    mounts = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        "/media/external/data-vault/services" = "data-vault/services";
      };
      description = ''
        ZFS datasets to mount, keyed by mountpoint. The datasets must have
        `mountpoint=legacy`: systemd, not `zfs mount -a`, mounts them, so
        services can depend on them with `RequiresMountsFor=` and will not
        start if a dataset failed to mount (e.g. its encryption key could not be
        loaded). A failed mount does not block boot.
      '';
    };

    smbShares = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        data_vault_private = "/media/external/data-vault/private";
      };
      description = ''
        Samba shares, keyed by share name, readable and writable by every
        authenticated Samba user. Samba only starts once their paths are mounted.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    boot = {
      supportedFilesystems = [ "zfs" ];
      zfs.forceImportRoot = false;
      zfs.extraPools = cfg.extraPools;
    };

    networking.hostId = builtins.substring 0 8 (
      builtins.hashString "sha512" config.networking.hostName
    );

    services.zfs.autoScrub.enable = true;

    # Free-space reserve (not declarative: NixOS does not manage dataset
    # properties). Each pool keeps ~10% of its usable space in an empty,
    # unmounted dataset so writes fail before the pool gets so full that
    # performance degrades. Recreate it after rebuilding a pool:
    #   zfs create -o reservation=0.9T -o mountpoint=none -o canmount=off data-vault/reserved
    # Resize with `zfs set reservation=<size> <pool>/reserved`.
    # Monitoring alerts on the remaining usable space (monitoring/prometheus/alerts.yml).

    # Encryption keys need no extra service: each zfs-import-<pool> unit loads
    # the keys of its datasets (`file://` keylocations included) right after
    # importing the pool (boot.zfs.requestEncryptionCredentials).

    # Datasets use legacy mountpoints, so a new dataset needs a `mounts` entry
    # before it gets mounted. Children inherit `legacy` from the pool root:
    #   zfs create -o encryption=on -o keyformat=raw \
    #     -o keylocation=file:///etc/secrets/zfs/<name>.key <pool>/<name>
    # nofail keeps a failed mount (e.g. missing key) from dropping the headless
    # server into emergency mode; dependent services fail instead.
    fileSystems = lib.mapAttrs (_: dataset: {
      device = dataset;
      fsType = "zfs";
      options = [ "nofail" ];
    }) cfg.mounts;

    # Ensure nfs support for shared pools
    networking.firewall.allowedTCPPorts = [ 2049 ];

    services.nfs.server.enable = true;

    # Ensure samba support for shared pools. Shares are declared here rather
    # than with the `sharesmb` dataset property, which legacy mountpoints do
    # not support.
    services.samba = {
      enable = true;
      settings = lib.mapAttrs (_: path: {
        inherit path;
        "read only" = "no";
        "guest ok" = "no";
      }) cfg.smbShares;
      openFirewall = true;
    };

    # Never serve the empty mountpoint of a dataset that failed to mount.
    systemd.services.samba-smbd.unitConfig.RequiresMountsFor = lib.attrValues cfg.smbShares;

    services.samba-wsdd = {
      enable = true;
      openFirewall = true;
    };
  };
}
