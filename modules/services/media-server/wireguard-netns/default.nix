{
  lib,
  config,
  pkgs,
  sops,
  ...
}:

let
  cfg = config.modules.services.media-server.wireguard-netns;
in
{
  options.modules.services.media-server.wireguard-netns = {
    enable = lib.mkEnableOption "Whether to enable custom wireguard-netns settings.";

    namespace = lib.mkOption {
      type = lib.types.str;
      description = "Network namespace to be created";
      default = "wg";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      "vpn/ipv4" = {
        restartUnits = [ "${cfg.namespace}.service" ];
      };
      "vpn/wg.conf" = {
        restartUnits = [ "${cfg.namespace}.service" ];
      };
    };

    systemd.services."netns@" = {
      description = "%I network namespace";
      before = [ "network.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.iproute2}/bin/ip netns add %I";
        ExecStop = "${pkgs.iproute2}/bin/ip netns del %I";
      };
    };

    systemd.services.${cfg.namespace} = {
      description = "${cfg.namespace} network interface";
      bindsTo = [ "netns@${cfg.namespace}.service" ];
      requires = [ "network-online.target" ];
      after = [ "netns@${cfg.namespace}.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart =
          with pkgs;
          writers.writeBash "wg-up" ''
            set -e
            ${iproute2}/bin/ip link add wg0 type wireguard
            ${iproute2}/bin/ip link set wg0 netns ${cfg.namespace}
            ${iproute2}/bin/ip -n ${cfg.namespace} address add \
              $(${coreutils}/bin/cat ${config.sops.secrets."vpn/ipv4".path}) dev wg0
            ${iproute2}/bin/ip netns exec ${cfg.namespace} \
              ${wireguard-tools}/bin/wg setconf wg0 ${config.sops.secrets."vpn/wg.conf".path}
            ${iproute2}/bin/ip -n ${cfg.namespace} link set wg0 up
            ${iproute2}/bin/ip -n ${cfg.namespace} link set lo up
            ${iproute2}/bin/ip -n ${cfg.namespace} route add default dev wg0
          '';
        ExecStop =
          with pkgs;
          writers.writeBash "wg-down" ''
            ${iproute2}/bin/ip -n ${cfg.namespace} route del default dev wg0
            ${iproute2}/bin/ip -n ${cfg.namespace} link del wg0
          '';
      };
    };
  };
}
