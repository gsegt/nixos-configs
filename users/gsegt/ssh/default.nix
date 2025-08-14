{
  programs.ssh = {
    enable = true;
    extraConfig = ''
      #: github.com - commit/pull/push to github.com
      Host github.com gist.github.com
          HostName github.com
          IdentityFile ~/.ssh/github
    '';
  };
}
