{ pkgs, ... }:

{
  users.users.gsegt = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "changeme";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDwPeKHdo/JDZ4TsrOVzgY2mEjTi1vL6UZzJ4ulaJpaY"
    ];
    shell = pkgs.fish;
  };

  programs.fish.enable = true;

  security.sudo.extraRules = [
    {
      users = [ "gsegt" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
