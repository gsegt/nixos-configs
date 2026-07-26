{ config, wsl, ... }:

{
  imports = [ ../../modules ];

  modules.base = {
    enable = true;
    userName = "gsegt";
    groupName = "gsegt";
    uid = 1000;
    gid = 1000;
    hostName = "wsl";
    timeZone = "Europe/Paris";
  };

  wsl = {
    enable = true;
    defaultUser = config.modules.base.userName;
  };
}
