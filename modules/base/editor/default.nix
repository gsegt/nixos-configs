{ lib, config, ... }:

let
  cfg = config.modules.base.editor;
in
{
  options.modules.base.editor = {
    enable = lib.mkEnableOption "Enable common editor settings for all systems";
  };

  config = lib.mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };
  };
}
