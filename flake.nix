{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-server.url = "github:NixOS/nixpkgs/nixos-26.05-small";
    home-manager-server = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs-server";
    };
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-server,
      home-manager,
      home-manager-server,
      sops-nix,
      nixos-wsl,
      ...
    }@inputs:
    let
      # Each host picks its nixpkgs channel and the matching home-manager release,
      # everything else is shared. All flake inputs are available to modules as `inputs`.
      mkHost =
        {
          nixpkgs,
          home-manager,
          modules,
        }:
        nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            home-manager.nixosModules.home-manager
            sops-nix.nixosModules.sops
          ]
          ++ modules;
        };
    in
    {
      nixosConfigurations = {
        wsl = mkHost {
          inherit nixpkgs home-manager;
          modules = [
            nixos-wsl.nixosModules.wsl
            ./machines/wsl
          ];
        };
        aspire = mkHost {
          nixpkgs = nixpkgs-server;
          home-manager = home-manager-server;
          modules = [ ./machines/aspire ];
        };
      };
    };
}
