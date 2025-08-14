{ config, username, ... }:

{
  imports =
    let
      thisDir = ./.;
      folders = builtins.filter (name: builtins.pathExists (thisDir + "/${name}/default.nix")) (
        builtins.attrNames (builtins.readDir thisDir)
      );
    in
    map (name: thisDir + "/${name}") folders;

  home.username = username;
  home.homeDirectory = "/home/${username}";

  home.stateVersion = "25.05";
}
