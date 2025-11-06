{ lib, config, ... }:

let
  cfg = config.modules.base.nix;
in
{
  options.modules.base.nix = {
    enable = lib.mkEnableOption "Whether to enable custom nix settings.";
  };

  config = lib.mkIf cfg.enable {
    nix = {
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        download-buffer-size = 268435456; # 256 MiB
      };
      gc = {
        automatic = true;
        options = "--delete-older-than 7d";
      };
      optimise.automatic = true;
    };

    programs.nix-ld.enable = true; # Allow unpatched dynamic binaries, like VSCode remote
  };
}
