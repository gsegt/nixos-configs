{ lib, config, ... }:

let
  service = "opencloud";
  cfg = config.modules.services.${service};
in
{
  options.modules.services.${service} = {
    enable = lib.mkEnableOption "Whether to enable custom ${service} settings.";

    stateDir = lib.mkOption {
      type = lib.types.path;
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."opencloud/env" = {
      owner = config.services.${service}.user;
      group = config.services.${service}.group;
    };

    services.${service} = {
      enable = true;
      url = "https://${service}.${config.modules.services.reverse-proxy.domain}";
      stateDir = cfg.stateDir;
      environment = {
        PROXY_TLS = "false";
        # Disabled until collabora is enabled
        # OC_ADD_RUN_SERVICES = "collaboration";
        # COLLABORATION_APP_NAME = "Office";
        # COLLABORATION_APP_PRODUCT = "Collabora";
        # COLLABORATION_APP_ADDR = "http://[::1]:${toString config.services.collabora-online.port}";
        # COLLABORATION_APP_INSECURE = "true";
        # COLLABORATION_WOPI_SRC = "https://${config.services.collabora-online.settings.server_name}";
        # COLLABORATION_APP_PROOF_DISABLE = "true";
      };
      environmentFile = config.sops.secrets."opencloud/env".path;
      settings = {
        # Disabled until collabora is enabled
        # # An override of the default CSP: every parameter has to be re-written, default can be found on opencloud's compose files
        # csp = {
        #   directives = {
        #     child-src = [
        #       "'self'"
        #     ];
        #     connect-src = [
        #       "'self'"
        #       "blob:"
        #       "https://raw.githubusercontent.com/opencloud-eu/awesome-apps/"
        #       "https://\${IDP_DOMAIN|keycloak.opencloud.test}\${TRAEFIK_PORT_HTTPS}/"
        #       "https://update.opencloud.eu/"
        #     ];
        #     default-src = [
        #       "'none'"
        #     ];
        #     font-src = [
        #       "'self'"
        #     ];
        #     frame-ancestors = [
        #       "'self'"
        #     ];
        #     frame-src = [
        #       "'self'"
        #       "blob:"
        #       "https://embed.diagrams.net"

        #       # Here is the culprit, put your own office service's URL
        #       "https://${config.services.collabora-online.settings.server_name}"

        #       # This is needed for the external-sites web extension when embedding sites
        #       "https://docs.opencloud.eu"
        #     ];
        #     img-src = [
        #       "'self'"
        #       "data:"
        #       "blob:"
        #       "https://raw.githubusercontent.com/opencloud-eu/awesome-apps/"
        #       "https://tile.openstreetmap.org/"
        #     ];
        #     manifest-src = [
        #       "'self'"
        #     ];
        #     media-src = [
        #       "'self'"
        #     ];
        #     object-src = [
        #       "'self'"
        #       "blob:"
        #     ];
        #     script-src = [
        #       "'self'"
        #       "'unsafe-inline'"
        #       "https://\${IDP_DOMAIN|keycloak.opencloud.test}\${TRAEFIK_PORT_HTTPS}/"
        #     ];
        #     style-src = [
        #       "'self'"
        #       "'unsafe-inline'"
        #     ];
        #   };
        # };
        # proxy = {
        #   # Tell your proxy to look at that CSP file you created
        #   csp_config_file_location = "/etc/opencloud/csp.yaml";
        # };
      };
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.stateDir} 0755 ${config.services.${service}.user} ${config.services.${service}.group} - -"
    ];

    services.${config.modules.services.reverse-proxy.service} = {
      virtualHosts."${service}.${config.modules.services.reverse-proxy.domain}".extraConfig = ''
        reverse_proxy ${config.services.${service}.address}:${toString config.services.${service}.port}
      '';
    };

    modules.services.dyndns-ovh.subdomains = [
      "${service}"
    ];
  };
}
