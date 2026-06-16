{
  description = "Flake exporting a configured hilbish package";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    wrappers = {
      url = "github:BirdeeHub/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      wrappers,
      flake-parts,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ wrappers.flakeModules.wrappers ];
      systems = nixpkgs.lib.platforms.all;

      perSystem =
        { config, pkgs, ... }:
        {
          packages.default = config.packages.hilbish;
          checks.default = import ./wrapperModules/check.nix { inherit pkgs self; }; # NOTE: per fare i checks
        };

      flake = {
        wrappers.hilbish = ./module.nix;
        #wrapperModules.hilbish = ./wrapperModules/module.nix;

        nixosModules = {
          hilbish = wrappers.lib.getInstallModule {
            name = "hilbish";
            value = self.wrapperModules.hilbish;
          };
          default = self.nixosModules.hilbish;
        };

        homeModules = {
          hilbish = wrappers.lib.getInstallModule {
            name = "hilbish";
            value = self.wrapperModules.hilbish;
          };
          default = self.homeModules.hilbish;
        };

        overlays = {
          hilbish = final: _: { hilbish = self.wrappers.hilbish.wrap { pkgs = final; }; };
          default = self.overlays.hilbish;
        };
      };
    };
}
