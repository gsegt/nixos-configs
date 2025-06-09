{ config, ... }:

{
  home.username = "gsegt";
  home.homeDirectory = "/home/${config.home.username}";

  programs.git = {
    enable = true;
    userName = "${config.home.username}";
    userEmail = "git@gsegt.eu";
    extraConfig = {
      core = {
        autocrlf = "input";
        eol = "lf";
      };
      init = {
        defaultBranch = "main";
      };
      pull = {
        rebase = "true";
      };
      rebase.autostash = "true";
    };
  };

  home.stateVersion = "25.05";
}
