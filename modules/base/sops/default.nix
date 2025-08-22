{
  lib,
  config,
  pkgs,
  sops,
  ...
}:

let
  cfg = config.modules.base.sops;
in
{
  options.modules.base.sops = {
    enable = lib.mkEnableOption "Whether to enable custom sops settings.";
  };

  config = lib.mkIf cfg.enable {
    sops = {
      defaultSopsFile = ../../../secrets/default.yaml;
      age.keyFile = "/etc/secrets/sops/age/keys.txt"; # Use absolute path to avoid conflict with nix store
    };
  };
}
