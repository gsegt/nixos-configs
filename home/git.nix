{
  programs.git = {
    enable = true;
    userName = "gsegt";
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
}
