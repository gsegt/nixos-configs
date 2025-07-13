{ pkgs, ... }:

{
  imports = [
    ./docker.nix
    ./editor.nix
    ./environment-variables.nix
    ./hardware-configuration.nix
    ./nfs.nix
    ./remote-unlock.nix
    ./samba.nix
    ./ssh.nix
    ./upgrade-diff.nix
    ./user.nix
    ./zfs.nix
    ./zram.nix
  ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  environment.systemPackages = with pkgs; [
    git # Necessary for home manager
  ];

  networking.hostName = "aspire";
  networking.nameservers = [
    "1.1.1.1"
    "1.0.0.1"
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  services.logind.lidSwitch = "ignore";

  time.timeZone = "Europe/Paris";

  system.stateVersion = "25.05";
}
