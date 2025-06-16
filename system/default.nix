{ pkgs, ... }:

{
  imports = [
    ./docker.nix
    ./editor.nix
    ./environment-variables.nix
    ./hardware-configuration.nix
    ./user.nix
    ./zfs.nix
    ./zram.nix
  ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };
  boot.initrd.checkJournalingFS = false;

  environment.systemPackages = with pkgs; [
    git # Necessary for home manager
  ];

  networking.hostName = "nixos";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  services.openssh.enable = true;

  services.logind.lidSwitch = "ignore";

  time.timeZone = "Europe/Paris";

  system.stateVersion = "25.05";
}
