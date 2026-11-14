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
      description = "Name or GUID of extra ZFS pools that you wish to import during boot.";
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

    # Ensure samba support for shared pools
    services.samba = {
      enable = true;
      settings = {
        global = {
          "usershare path" = "/var/lib/samba/usershares";
          "usershare max shares" = "100";
          "usershare allow guests" = "yes";
          "usershare owner only" = "no";
        };
      };
      openFirewall = true;
    };

    services.samba-wsdd = {
      enable = true;
      openFirewall = true;
    };

    systemd.tmpfiles.rules = [ "d /var/lib/samba/usershares 1775 root root -" ];
  };
}
