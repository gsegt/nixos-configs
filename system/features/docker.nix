{ username, ... }:

{
  # Used instead of users.users.<myuser>.extraGroups = [ "docker" ]; to maintain modularity
  users.extraGroups.docker.members = [ username ];

  virtualisation.docker.enable = true;
}
