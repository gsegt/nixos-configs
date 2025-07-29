{
  pkgs,
  username,
  hostname,
  ...
}:

{
  imports = [
    ./editor
    ./environment-variables
    ./user
    ./zram
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

  environment.systemPackages = with pkgs; [
    git # Necessary for home manager
    nixfmt-rfc-style # For formatting Nix files
  ];

  programs.nix-ld.enable = true; # Allow unpatched dynamic binaries, like VSCode remote

  networking.hostName = hostname;

  system.stateVersion = "25.05";
}
