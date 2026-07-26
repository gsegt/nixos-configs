{ pkgs, ... }:

{
  home.packages = with pkgs; [
    btop
    intel-gpu-tools
  ];
}
