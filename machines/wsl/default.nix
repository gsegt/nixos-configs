{ config, wsl, ... }:

{
  imports = [ ../../modules ];

  modules.base.enable = true;
  modules.base.username = "gsegt";
  modules.base.hostname = "wsl";

  wsl.enable = true;
  wsl.defaultUser = config.modules.base.username;
}
