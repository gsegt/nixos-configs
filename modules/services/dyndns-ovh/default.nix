{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.modules.services.dyndns-ovh;
  dyndnsScript = pkgs.writeShellScriptBin "dyndns-ovh" ''
    BASE_DOMAIN=${config.modules.services.reverse-proxy.domain}
    SUBDOMAINS=(${lib.concatStringsSep " " cfg.subdomains})
    LOGIN=$(cat ${config.sops.secrets."dyndns-ovh/login".path})
    PASSWORD=$(cat ${config.sops.secrets."dyndns-ovh/password".path})
    DNSSERVER=@dns104.ovh.net
    CURRENT_IP=$(${pkgs.curl}/bin/curl -m 5 -4 ifconfig.co 2>/dev/null)

    for SUBDOMAIN in ''\${SUBDOMAINS[@]}; do
      HOST_IP=
      HOST=$SUBDOMAIN.$BASE_DOMAIN

      echo "Updating DynHost for $HOST"

      HOST_IP=$(${pkgs.dig}/bin/dig $DNSSERVER +short $HOST A)

      if [ -z $CURRENT_IP ] || [ -z $HOST_IP ]; then
        echo "No IP retrieved"
        echo "HOST_IP=$HOST_IP"
        echo "CURRENT_IP=$CURRENT_IP"
      else
        if [ "$HOST_IP" != "$CURRENT_IP" ]; then
          RES=$(${pkgs.curl}/bin/curl -m 5 -L --location-trusted --user "$LOGIN:$PASSWORD" "https://www.ovh.com/nic/update?system=dyndns&hostname=$HOST&myip=$CURRENT_IP")
          echo "IPv4 has changed - request to OVH DynHost: $RES"
        else
          echo "IPv4 has not changed - no request to OVH DynHost"
        fi
      fi
    done
  '';
in
{
  options.modules.services.dyndns-ovh = {
    enable = lib.mkEnableOption "Whether to enable custom dyndns-ovh settings.";

    subdomains = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of all the subdomains to update";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.dyndns-ovh = {
      description = "OVH DynDNS IP updater";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${dyndnsScript}/bin/dyndns-ovh";
      };
    };

    systemd.timers.dyndns-ovh = {
      description = "Run OVH DynDNS IP updater every hour";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "hourly";
        Persistent = true;
      };
    };

    environment.systemPackages = with pkgs; [
      dig
      curl
    ];

    sops.secrets = {
      "dyndns-ovh/login" = { };
      "dyndns-ovh/password" = { };
    };
  };
}
