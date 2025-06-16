{ ... }:

{
  users.extraGroups.docker.members = [ "gsegt" ];

  virtualisation.docker.enable = true;
}
