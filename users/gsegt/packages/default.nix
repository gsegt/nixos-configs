{ pkgs, ... }:

{
  home.packages = with pkgs; [
    btop
    jq
    yq-go
  ];
}
