{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "Host github.com gist.github.com" = {
        HostName = "github.com";
        IdentityFile = "~/.ssh/github";
        IdentitiesOnly = true;
      };
      "Host aspire" = {
        HostName = "192.168.1.253";
        User = "gsegt";
        IdentityFile = "~/.ssh/servers";
        IdentitiesOnly = true;
      };
      "Host unlock-aspire" = {
        HostName = "192.168.1.253";
        User = "root";
        IdentityFile = "~/.ssh/unlock-aspire";
        IdentitiesOnly = true;
        # The initrd has its own host key, store it separately from the booted system's.
        HostKeyAlias = "unlock-aspire";
      };
    };
  };
}
