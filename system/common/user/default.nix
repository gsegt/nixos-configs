{ pkgs, username, ... }:

{
  users.users.${username} = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDwPeKHdo/JDZ4TsrOVzgY2mEjTi1vL6UZzJ4ulaJpaY"
    ];
    shell = pkgs.fish;
  };

  security.sudo.wheelNeedsPassword = false; # Technically redundant for wsl systems

  programs.fish.enable = true; # Needs to be installed system wide for user to login
}
