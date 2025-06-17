{ config, ... }:

{
  imports = [
    ./git.nix
    ./shell.nix
  ];

  home.username = "gsegt";
  home.homeDirectory = "/home/${config.home.username}";

  home.stateVersion = "25.05";
}
