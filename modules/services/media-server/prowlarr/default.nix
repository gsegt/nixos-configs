{
  pkgs,
  lib,
  config,
  ...
}:

let
  service = "prowlarr";
  cfg = config.modules.services.media-server.${service};
in
{
  options.modules.services.media-server.${service} = {
    enable = lib.mkEnableOption "Whether to enable custom ${service} settings.";
  };

  config = lib.mkIf cfg.enable {
    services.${service} = {
      enable = true;
      openFirewall = true;
    };

    systemd.tmpfiles.rules = [
      "d ${config.services.prowlarr.dataDir}/Definitions/Custom 0755 nobody nogroup -"
    ];

    systemd.services.prowlarr-file-deploy = {
      description = "Deploy ygege.yml for Prowlarr";
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script = ''
        mkdir -p ${config.services.prowlarr.dataDir}/Definitions/Custom
        ${pkgs.coreutils}/bin/install -m 644 -o nobody -g nogroup ${./ygege.yml} ${config.services.prowlarr.dataDir}/Definitions/Custom/ygege.yml
      '';
    };
  };
}
