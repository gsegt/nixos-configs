{
  lib,
  config,
  ...
}:

let
  cfg = config.system.common.nix;
in
{
  options.system.common.nix = {
    enable = lib.mkEnableOption "Enable common nix settings for all systems";
  };

  config = lib.mkIf cfg.enable {
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    nix.optimise.automatic = true;

    programs.nix-ld.enable = true; # Allow unpatched dynamic binaries, like VSCode remote
  };
}
