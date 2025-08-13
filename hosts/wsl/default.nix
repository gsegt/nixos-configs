{ config, wsl, ... }:

{
  imports = [ ../../system ];

  system.common.enable = true;
  system.common.username = "gsegt";
  system.common.hostname = "wsl";

  wsl.enable = true;
  wsl.defaultUser = config.system.common.username;
}
