{ config, username, ... }:

let
  utils = import ../../utils;
in
{
  imports = utils.importSubmodules { dir = ./.; };

  home.username = username;
  home.homeDirectory = "/home/${username}";

  home.stateVersion = "25.05";
}
