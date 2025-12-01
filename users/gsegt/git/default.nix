{
  programs.git = {
    enable = true;
    settings = {
      advice = {
        skippedCherryPicks = "false";
      };
      core = {
        autocrlf = "input";
      };
      init = {
        defaultBranch = "main";
      };
      pull = {
        rebase = "true";
      };
      push = {
        autoSetupRemote = "true";
      };
      rebase = {
        autosquash = "true";
        autostash = "true";
      };
      user = {
        email = "git@gsegt.eu";
        name = "gsegt";
      };
    };
  };
}
