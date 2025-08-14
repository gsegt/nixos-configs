{ dir }:

let
  folders = builtins.filter (name: builtins.pathExists (dir + "/${name}/default.nix")) (
    builtins.attrNames (builtins.readDir dir)
  );
in
map (name: dir + "/${name}") folders
