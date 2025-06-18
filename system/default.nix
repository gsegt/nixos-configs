{ pkgs, ... }:

{
  imports = [
    ./docker.nix
    ./editor.nix
    ./environment-variables.nix
    ./hardware-configuration.nix
    ./user.nix
    ./zram.nix
  ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };
  boot.initrd.checkJournalingFS = false;

  networking.hostName = "nixos";

  time.timeZone = "Europe/Paris";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  environment.systemPackages = with pkgs; [
    git
  ];

  services.openssh.enable = true;

  services.logind.lidSwitch = "ignore";

  system.stateVersion = "25.05";
}
