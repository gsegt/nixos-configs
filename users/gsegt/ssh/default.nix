{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "github.com gist.github.com" = {
        hostname = "github.com";
        identityFile = "~/.ssh/github";
      };
    };
  };
}
