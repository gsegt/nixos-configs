{ config, ... }:

{
  imports = [
    ./git.nix
    ./shell.nix
    ./ssh.nix
    ./upgrade-diff.nix
  ];

  home.username = "acer";
  home.homeDirectory = "/home/${config.home.username}";

  home.stateVersion = "25.05";
}
