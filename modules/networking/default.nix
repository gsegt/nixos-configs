let
  utils = import ../../utils;
in
{
  imports = utils.importSubmodules { dir = ./.; };
}
