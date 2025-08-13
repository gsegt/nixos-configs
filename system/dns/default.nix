{
  lib,
  config,
  ...
}:

let
  cfg = config.system.dns;
in
{
  options.system.dns = {
    enable = lib.mkEnableOption "Enable custom dns settings.";
  };

  config = lib.mkIf cfg.enable {
    networking.nameservers = [
      "1.1.1.1"
      "1.0.0.1"
    ];
  };
}
