{ config, wsl, ... }:

{
  imports = [ ../../common ];
  common.enable = true;
  common.username = "gsegt";
  common.hostname = "wsl";

  wsl.enable = true;
  wsl.defaultUser = config.common.username;
}
