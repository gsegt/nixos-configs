{ wsl, username, ... }:

{
  imports = [ ../../common ];

  wsl.enable = true;
  wsl.defaultUser = username;
}
