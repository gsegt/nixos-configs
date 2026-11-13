{ inputs, ... }:

let
  aspire = inputs.self.nixosConfigurations.aspire.config;
in
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
        HostName = aspire.modules.base.ipAddress;
        User = aspire.modules.base.userName;
        IdentityFile = "~/.ssh/servers";
        IdentitiesOnly = true;
      };
      "Host unlock-aspire" = {
        HostName = aspire.modules.base.ipAddress;
        User = "root";
        IdentityFile = "~/.ssh/unlock-aspire";
        IdentitiesOnly = true;
        # The initrd has its own host key, store it separately from the booted system's.
        HostKeyAlias = "unlock-aspire";
      };
    };
  };
}
