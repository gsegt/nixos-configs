{ lib, config, ... }:

let
  cfg = config.modules.networking.dns;
in
{
  options.modules.networking.dns = {
    enable = lib.mkEnableOption "Whether to enable custom DNS settings.";
  };

  config = lib.mkIf cfg.enable {
    networking.nameservers = [
      "1.1.1.1"
      "1.0.0.1"
    ];
  };
}
