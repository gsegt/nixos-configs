{
  programs.ssh = {
    enable = true;
    matchBlocks = {
      "github.com gist.github.com" = {
        hostname = "github.com";
        identityFile = "~/.ssh/github";
      };
    };
  };
}
