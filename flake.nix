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
    nixpkgs-server.url = "github:NixOS/nixpkgs/nixos-25.05-small";
    home-manager-server = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs-server";
    };
    sops-nix-server.url = "github:Mic92/sops-nix";
    sops-nix-server.inputs.nixpkgs.follows = "nixpkgs-server";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      sops-nix,
      nixos-wsl,
      nixpkgs-server,
      home-manager-server,
      sops-nix-server,
      ...
    }:
    {
      nixosConfigurations.wsl = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          home-manager.nixosModules.home-manager
          sops-nix.nixosModules.sops
          nixos-wsl.nixosModules.wsl
          ./machines/wsl
        ];
      };
      nixosConfigurations.aspire = nixpkgs-server.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          home-manager-server.nixosModules.home-manager
          sops-nix-server.nixosModules.sops
          ./machines/aspire
        ];
      };
    };
}
