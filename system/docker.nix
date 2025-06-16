{
  # Used instead of users.users.<myuser>.extraGroups = [ "docker" ]; to maintain modularity
  users.extraGroups.docker.members = [ "gsegt" ];

  virtualisation.docker.enable = true;
}
