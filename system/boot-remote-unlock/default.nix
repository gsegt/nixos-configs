{ lib, config, ... }:

let
  cfg = config.system.boot-remote-unlock;
in
{
  options.system.boot-remote-unlock = {
    enable = lib.mkEnableOption "Enable remote unlocking of encrypted devices.";

    ip = lib.mkOption {
      type = lib.types.str;
      description = "IP address for the remote unlocking interface.";
    };

    gateway = lib.mkOption {
      type = lib.types.str;
      description = "Gateway for the remote unlocking interface.";
    };

    mask = lib.mkOption {
      type = lib.types.str;
      description = "Network mask for the remote unlocking interface.";
    };

    networkKernelModules = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Kernel modules required for network access during initrd.";
    };

  };

  config = lib.mkIf cfg.enable {
    boot.initrd = {
      availableKernelModules = cfg.networkKernelModules;
      network = {
        enable = true;
        ssh = {
          enable = true;
          port = 22;
          authorizedKeys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEf5Nt/JVAhptEaxDU/5Rdf284QswbVpKOOWFf7o5RAk"
          ];
          hostKeys = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
        };
        postCommands = ''
          # Automatically ask for the password on SSH login
          echo 'cryptsetup-askpass || echo "Unlock was successful; exiting SSH session" && exit 1' >> /root/.profile
        '';
      };
    };

    boot.kernelParams = [
      "ip=${cfg.ip}::${cfg.gateway}:${cfg.mask}:${config.networking.hostName}"
    ];
  };
}
