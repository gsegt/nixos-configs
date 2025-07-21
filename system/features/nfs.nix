{
  networking.firewall.allowedTCPPorts = [ 2049 ];

  services.nfs.server.enable = true;
}
