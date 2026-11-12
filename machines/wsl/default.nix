{ config, wsl, ... }:

{
  imports = [ ../../modules ];

  nixpkgs.hostPlatform = "x86_64-linux";

  wsl = {
    enable = true;
    defaultUser = config.modules.base.userName;
  };

  modules.base = {
    enable = true;
    userName = "gsegt";
    groupName = "gsegt";
    uid = 1000;
    gid = 1000;
    hostName = "wsl";
    timeZone = "Europe/Paris";
  };

  modules.claude-code.enable = true;
}
