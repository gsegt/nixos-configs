{ lib, config, ... }:

let
  cfg = config.modules.base.editor;
in
{
  options.modules.base.editor = {
    enable = lib.mkEnableOption "Whether to enable custom editor settings.";
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
