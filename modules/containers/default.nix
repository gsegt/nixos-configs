{ lib, config, ... }:

let
  cfg = config.modules.containers;
in
{
  options.modules.containers = {
    enable = lib.mkEnableOption "Whether to enable custom containers settings.";
  };

  config = lib.mkIf cfg.enable {
    # Runtime
    virtualisation.podman = {
      enable = true;
      autoPrune.enable = true;
      dockerCompat = true;
    };

    # Enable container name DNS for all Podman networks.
    networking.firewall.interfaces =
      let
        matchAll = if !config.networking.nftables.enable then "podman+" else "podman*";
      in
      {
        "${matchAll}".allowedUDPPorts = [ 53 ];
      };
  };
}
