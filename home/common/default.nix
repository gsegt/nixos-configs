{ config, username, ... }:

{
  imports = [
    ./git
    ./shell
    ./ssh
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";

  home.stateVersion = "25.05";
}
