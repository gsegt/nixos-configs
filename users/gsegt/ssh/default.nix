{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "Host github.com gist.github.com" = {
        HostName = "github.com";
        IdentityFile = "~/.ssh/github";
      };
    };
  };
}
