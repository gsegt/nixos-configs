{
  programs.git = {
    enable = true;
    userName = "gsegt";
    userEmail = "git@gsegt.eu";
    # Sections are to mimic the final configuration
    extraConfig = {
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
      rebase = {
        autosquash = "true";
        autostash = "true";
      };
    };
  };
}
