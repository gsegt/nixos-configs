{
  pkgs,
  lib,
  config,
  ...
}:

let
  service = "valheim";
  valheim_harmless_midock_ports = [
    2456
    2457
  ];
  valheim_overc_loc_ports = [
    2458
    2459
  ];
  valheim_harmless_midock_subdomain = service + "-harmless-midock";
  valheim_harmless_midock_uri = "${valheim_harmless_midock_subdomain}.${config.modules.services.reverse-proxy.domain}";
  valheim_overc_loc_subdomain = service + "-overc-loc";
  valheim_overc_loc_uri = "${valheim_overc_loc_subdomain}.${config.modules.services.reverse-proxy.domain}";
  valheim_uid = 1000;
  valheim_gid = 1000;
  valheim_harmless_midock_volume_dir = "${cfg.volumeDir}/harmless-midock";
  valheim_harmless_midock_server_dir = "${valheim_harmless_midock_volume_dir}/valheim";
  valheim_harmless_midock_saves_dir = "${valheim_harmless_midock_volume_dir}/valheim-saves";
  valheim_overc_loc_volume_dir = "${cfg.volumeDir}/overc-loc";
  valheim_overc_loc_server_dir = "${valheim_overc_loc_volume_dir}/valheim";
  valheim_overc_loc_saves_dir = "${valheim_overc_loc_volume_dir}/valheim-saves";

  cfg = config.modules.services.${service};
in
{
  options.modules.services.${service} = {
    enable = lib.mkEnableOption "Whether to enable custom ${service} settings.";

    volumeDir = lib.mkOption {
      type = lib.types.path;
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      "valheim/harmless-midock/env" = { };
      "valheim/overc-loc/env" = { };
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.volumeDir} 0755 ${config.modules.base.userName} ${config.modules.base.groupName} - -"
      "d ${valheim_harmless_midock_volume_dir} 0755 ${toString valheim_uid} ${toString valheim_gid} - -"
      "d ${valheim_harmless_midock_server_dir} 0755 ${toString valheim_uid} ${toString valheim_gid} - -"
      "d ${valheim_harmless_midock_saves_dir} 0755 ${toString valheim_uid} ${toString valheim_gid} - -"
      "d ${valheim_overc_loc_volume_dir} 0755 ${toString valheim_uid} ${toString valheim_gid} - -"
      "d ${valheim_overc_loc_server_dir} 0755 ${toString valheim_uid} ${toString valheim_gid} - -"
      "d ${valheim_overc_loc_saves_dir} 0755 ${toString valheim_uid} ${toString valheim_gid} - -"
    ];

    networking.firewall.allowedUDPPorts = valheim_harmless_midock_ports ++ valheim_overc_loc_ports;

    # Containers
    virtualisation.oci-containers.containers."valheim-harmless-midock" = {
      image = "docker.io/indifferentbroccoli/valheim-server-docker:latest";
      environment = {
        "BEPINEXPACK_VERSION" = "5.4.2351";
        "BEPINEX_ENABLED" = "true";
        "CROSSPLAY_ENABLED" = "false";
        "MODIFIER_RESOURCES" = "muchmore";
        "MODS" =
          "MidnightMods-AchievementEnabler-0.5.1,Grantapher-ValheimPlus_Grantapher_Temporary-10.4.0,ValheimModding-Jotunn-2.30.2,ViperAlpha-EquipmentAndQuickSlotsByViper-3.1.5";
        "PGID" = "1000";
        "PORT" = "2456";
        "PUID" = "1000";
        "SERVER_NAME" = "harmless-midock";
        "UPDATE_ON_START" = "false";
        "WORLD_NAME" = "harmless-midock";
      };
      environmentFiles = [
        config.sops.secrets."valheim/harmless-midock/env".path
      ];
      volumes = [
        "${valheim_harmless_midock_server_dir}:/valheim:rw"
        "${valheim_harmless_midock_saves_dir}:/valheim-saves:rw"
      ];
      ports = [
        "${toString (builtins.elemAt valheim_harmless_midock_ports 0)}:2456/udp"
        "${toString (builtins.elemAt valheim_harmless_midock_ports 1)}:2457/udp"
      ];
      labels = {
        "compose2nix.settings.sops.secrets" = "valheim/harmless-midock/env";
        "io.containers.autoupdate" = "registry";
      };
      log-driver = "journald";
      extraOptions = [
        "--network-alias=harmless-midock"
        "--network=valheim"
      ];
    };
    systemd.services."podman-valheim-harmless-midock" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "podman-network-valheim.service"
      ];
      requires = [
        "podman-network-valheim.service"
      ];
      partOf = [
        "podman-compose-valheim-root.target"
      ];
      wantedBy = [
        "podman-compose-valheim-root.target"
      ];
    };
    virtualisation.oci-containers.containers."valheim-overc-loc" = {
      image = "docker.io/indifferentbroccoli/valheim-server-docker:latest";
      environment = {
        "BEPINEXPACK_VERSION" = "5.4.2351";
        "BEPINEX_ENABLED" = "true";
        "CROSSPLAY_ENABLED" = "false";
        "MODIFIER_RESOURCES" = "muchmore";
        "MODS" =
          "MidnightMods-AchievementEnabler-0.5.1,Grantapher-ValheimPlus_Grantapher_Temporary-10.4.0,ValheimModding-Jotunn-2.30.2,ViperAlpha-EquipmentAndQuickSlotsByViper-3.1.5";
        "PGID" = "1000";
        "PORT" = "2458";
        "PUID" = "1000";
        "SERVER_NAME" = "overc-loc";
        "UPDATE_ON_START" = "false";
        "WORLD_NAME" = "overc-loc";
      };
      environmentFiles = [
        config.sops.secrets."valheim/overc-loc/env".path
      ];
      volumes = [
        "${valheim_overc_loc_server_dir}:/valheim:rw"
        "${valheim_overc_loc_saves_dir}:/valheim-saves:rw"
      ];
      ports = [
        "${toString (builtins.elemAt valheim_overc_loc_ports 0)}:2458/udp"
        "${toString (builtins.elemAt valheim_overc_loc_ports 1)}:2459/udp"
      ];
      labels = {
        "compose2nix.settings.sops.secrets" = "valheim/overc-loc/env";
        "io.containers.autoupdate" = "registry";
      };
      log-driver = "journald";
      extraOptions = [
        "--network-alias=overc-loc"
        "--network=valheim"
      ];
    };
    systemd.services."podman-valheim-overc-loc" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "podman-network-valheim.service"
      ];
      requires = [
        "podman-network-valheim.service"
      ];
      partOf = [
        "podman-compose-valheim-root.target"
      ];
      wantedBy = [
        "podman-compose-valheim-root.target"
      ];
    };

    # Networks
    systemd.services."podman-network-valheim" = {
      path = [ pkgs.podman ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "podman network rm -f valheim";
      };
      script = ''
        podman network inspect valheim || podman network create valheim
      '';
      partOf = [ "podman-compose-valheim-root.target" ];
      wantedBy = [ "podman-compose-valheim-root.target" ];
    };

    # Root service
    # When started, this will automatically create all resources and start
    # the containers. When stopped, this will teardown all resources.
    systemd.targets."podman-compose-valheim-root" = {
      unitConfig = {
        Description = "Root target generated by compose2nix.";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
