let
  port = 9925;
in
{
  services.mealie = {
    enable = true;
    port = port;
    settings = {
      ALLOW_SIGNUP = "false";
      TZ = Europe/Paris;
    };
  };

  networking.firewall.allowedTCPPorts = [ port ];
}
