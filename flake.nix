{
  description = "Your new nix config";

  inputs = {
    # Nixpkgs
    #nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs.url = "github:nixos/nixpkgs/672430223ef43060b460321b50a2e17628c7d8cd";
    nixpkgs-discourse.url = "github:MTRNord/nixpkgs/beee2842bdc9281c94c95ea9c89f20b3da53ffd3";
    # You can access packages and modules from different nixpkgs revs
    # at the same time. Here's an working example:
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # Also see the 'unstable-packages' overlay at 'overlays/default.nix'.

    # Persistence
    impermanence.url = "github:nix-community/impermanence";

    # Home manager
    home-manager.url = "github:nix-community/home-manager/release-23.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # TODO: Add any other flake you might need
    hardware.url = "github:nixos/nixos-hardware";
    sops-nix.url = "github:Mic92/sops-nix";
    # Shameless plug: looking for a way to nixify your themes and make
    # everything match nicely? Try nix-colors!
    # nix-colors.url = "github:misterio77/nix-colors";

    kubenix.url = "github:hall/kubenix";
    docker-utils.url = "github:collinarnett/docker-utils";
  };

  outputs = { self, nixpkgs, nixpkgs-discourse, home-manager, sops-nix, docker-utils, ... }@inputs:
    let
      inherit (self) outputs;
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-linux"
        "x86_64-linux"
      ];
    in
    rec {
      # Your custom packages
      # Acessible through 'nix build', 'nix shell', etc
      packages = forAllSystems (system:
        let
          nixpkgs.legacyPackages.${system}.discourse = nixpkgs-discourse.legacyPackages.${system}.discourse;
          pkgs = nixpkgs.legacyPackages.${system};
          build-draupnir = {
            # TODO: Pull Draupnir
            # TODO: Run yarn describe version task
            # TODO: Build image using https://github.com/collinarnett/docker-utils
          };
        in
        import ./pkgs { inherit pkgs; }
      );

      # Devshell for bootstrapping
      # Acessible through 'nix develop' or 'nix-shell' (legacy)
      devShells = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in import ./shell.nix { inherit pkgs; }
      );

      formatter = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in pkgs.nixpkgs-fmt);

      # Your custom packages and modifications, exported as overlays
      overlays = import ./overlays { inherit inputs; pkgs = nixpkgs.legacyPackages.aarch64-linux; };
      # Reusable nixos modules you might want to export
      # These are usually stuff you would upstream into nixpkgs
      nixosModules = import ./modules/nixos;
      # Reusable home-manager modules you might want to export
      # These are usually stuff you would upstream into home-manager
      homeManagerModules = import ./modules/home-manager;

      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#your-hostname'
      nixosConfigurations = {
        worker-1 = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            # > Our main nixos configuration file <
            sops-nix.nixosModules.sops
            ./nixos/worker-1/configuration.nix
          ];
        };
      };

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager --flake .#your-username'
      homeConfigurations = {
        "marcel@worker-1" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.aarch64-linux; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            # > Our main home-manager configuration file <
            ./home-manager/home.nix
          ];
        };
      };
    };
}
