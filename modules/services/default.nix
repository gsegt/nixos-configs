{
  imports =
    let
      thisDir = ./.;
      folders = builtins.filter (name: builtins.pathExists (thisDir + "/${name}/default.nix")) (
        builtins.attrNames (builtins.readDir thisDir)
      );
    in
    map (name: thisDir + "/${name}") folders;
}
