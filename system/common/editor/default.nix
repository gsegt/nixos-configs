{
  lib,
  config,
  ...
}:

let
  cfg = config.system.common.editor;
in
{
  options.system.common.editor = {
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
