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
    ./nix
    ./user
    ./zram
  ];

  environment.systemPackages = with pkgs; [
    git # Necessary for home manager
    nixfmt-rfc-style # For formatting Nix files
  ];

  networking.hostName = hostname;

  system.stateVersion = "25.05";
}
