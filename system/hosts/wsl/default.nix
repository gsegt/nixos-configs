{ wsl, username, ... }:

{
  imports = [ ../../common.nix ];

  wsl.enable = true;
  wsl.defaultUser = username;
}
