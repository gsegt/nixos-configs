{
  # Used instead of users.users.<myuser>.extraGroups = [ "docker" ]; to maintain modularity
  users.extraGroups.docker.members = [ "acer" ];

  virtualisation.docker.enable = true;
}
