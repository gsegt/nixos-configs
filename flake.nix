{
  description = "NixOS configuration with flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05-small";
    vscode-server.url = "github:nix-community/nixos-vscode-server";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      vscode-server,
      home-manager,
      ...
    }@inputs:
    {
      nixosConfigurations.aspire = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vscode-server.nixosModules.default
          (
            { pkgs, ... }:
            {
              services.vscode-server.enable = true;
              environment.systemPackages = with pkgs; [
                nixfmt-rfc-style
              ];
            }
          )
          ./system
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.acer = import ./home;
          }
        ];
      };
    };
}
