{ config, ... }:

{
  imports = [
    ./git.nix
    ./shell.nix
    ./upgrade-diff.nix
  ];

  home.username = "gsegt";
  home.homeDirectory = "/home/${config.home.username}";

  home.stateVersion = "25.05";
}
