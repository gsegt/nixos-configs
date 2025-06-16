{
  services.samba = {
    enable = true;
    settings = {
      global = {
        "usershare path" = "/var/lib/samba/usershares";
        "usershare max shares" = "100";
        "usershare allow guests" = "yes";
        "usershare owner only" = "no";
      };
    };
    openFirewall = true;
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  systemd.tmpfiles.rules = [ "d /var/lib/samba/usershares 1775 root root -" ];

}
