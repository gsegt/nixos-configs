{ lib, config, ... }:

let
  cfg = config.modules.containers;
in
{
  options.modules.containers = {
    enable = lib.mkEnableOption "Whether to enable custom containers settings.";

    podmanInterfaces = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = if !config.networking.nftables.enable then "podman+" else "podman*";
      description = "Firewall interface glob matching every Podman bridge (iptables and nftables spell it differently).";
    };
  };

  config = lib.mkIf cfg.enable {
    # Runtime
    virtualisation.podman = {
      enable = true;
      autoPrune.enable = true;
      dockerCompat = true;
    };

    # Enable container name DNS for all Podman networks.
    networking.firewall.interfaces.${cfg.podmanInterfaces}.allowedUDPPorts = [ 53 ];
  };
}
