{ config, wsl, ... }:

{
  imports = [ ../../modules ];

  modules.base = {
    enable = true;
    userName = "gsegt";
    hostName = "wsl";
  };

  wsl = {
    enable = true;
    defaultUser = config.modules.base.userName;
  };
}
