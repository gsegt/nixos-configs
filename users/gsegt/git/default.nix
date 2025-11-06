{
  programs.git = {
    enable = true;
    userName = "gsegt";
    userEmail = "git@gsegt.eu";
    # Sections are to mimic the final configuration
    extraConfig = {
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
        autostash = "true";
        autosquash = "true";
      };
      advice = {
        skippedCherryPicks = "false";
      };
    };
  };
}
