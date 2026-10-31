{ lib, config, ... }:

let
  cfg = config.modules.boot.remote-unlock;
in
{
  options.modules.boot.remote-unlock = {
    enable = lib.mkEnableOption "Whether to enable custom settings for remote unlock of encrypted devices.";

    networkKernelModules = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Kernel modules required for network access during initrd.";
    };

    interface = lib.mkOption {
      type = lib.types.str;
      description = "Network interface for the remote unlocking.";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.initrd = {
      availableKernelModules = cfg.networkKernelModules;
      network = {
        enable = true;
        ssh = {
          enable = true;
          authorizedKeys = [
            ''command="systemctl default" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEf5Nt/JVAhptEaxDU/5Rdf284QswbVpKOOWFf7o5RAk''
          ];
          hostKeys = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
        };
      };
      systemd.network = {
        enable = true;
        networks."10-${cfg.interface}" = {
          matchConfig.Name = cfg.interface;
          networkConfig.DHCP = "ipv4";
          linkConfig.RequiredForOnline = "routable";
        };
      };
    };
  };
}
