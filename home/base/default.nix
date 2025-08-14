{ config, userName, ... }:

let
  utils = import ../../utils;
in
{
  imports = utils.importSubmodules { dir = ./.; };

  home.username = userName;
  home.homeDirectory = "/home/${userName}";

  home.stateVersion = "25.05";
}
