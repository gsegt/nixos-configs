{ config, username, ... }:

{
  imports = [
    ./common/git.nix
    ./common/shell.nix
    ./common/ssh.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";

  home.stateVersion = "25.05";
}
