{
  pkgs,
  username,
  hostname,
  ...
}:

{
  imports = [
    ./common/editor.nix
    ./common/environment-variables.nix
    ./common/user.nix
    ./common/zram.nix
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
