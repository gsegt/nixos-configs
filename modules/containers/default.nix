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
    virtualisation.oci-containers.backend = "podman";

    virtualisation.podman = {
      enable = true;
      autoPrune.enable = true;
      dockerCompat = true;
      defaultNetwork.settings = {
        # Required for container networking to be able to use names.
        dns_enabled = true;
      };
    };

    # Enable container name DNS for non-default Podman networks.
    # https://github.com/NixOS/nixpkgs/issues/226365
    networking.firewall.interfaces."podman+".allowedUDPPorts = [ 53 ];

    # Used instead of users.users.<myuser>.extraGroups = [ "podman" ]; to maintain modularity
    users.extraGroups.podman.members = [ config.modules.base.userName ];
  };
}
