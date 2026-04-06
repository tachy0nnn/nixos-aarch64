{
  description = "Personal nixos modules for aarch64 devices";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-23-11.url = "github:NixOS/nixpkgs/nixos-23.11";
    armbian = {
      url = "github:armbian/build";
      flake = false;
    };

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";

    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";

    devenv.url = "github:cachix/devenv";
    mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";
    nix2container.url = "github:nlewo/nix2container";
    nix2container.inputs.nixpkgs.follows = "nixpkgs";

    orangepi-uboot = {
      url = "github:orangepi-xunlong/u-boot-orangepi/v2017.09-rk3588";
      flake = false;
    };

    rkbin = {
      url = "github:rockchip-linux/rkbin";
      flake = false;
    };

    rkbin-armbian = {
      url = "github:armbian/rkbin";
      flake = false;
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } ({ self, ... }: {
      systems = [ "x86_64-linux" "aarch64-linux" ];

      flake = {
        nixosConfigurations.opi3b = inputs.nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = { inherit self inputs; };
          modules = [
            inputs.agenix.nixosModules.default
            ./hosts/opi3b/configuration.nix
          ];
        };

        deploy.nodes.opi3b = {
          hostname = "192.168.3.163";
          sshUser = "root";
          magicRollback = true;
          activationTimeout = 600;
          confirmTimeout = 60;
          profiles.system = {
            user = "root";
            path = inputs.deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.opi3b;
          };
        };
      };

      imports = [
        ./modules
        ./packages
        ./overlays
        inputs.devenv.flakeModule
      ];

      perSystem = { config, self', inputs', pkgs, system, ... }: {
        devShells.default = pkgs.mkShell {
          name = "nixos-aarch64";
          packages = [
            inputs.deploy-rs.packages.${system}.deploy-rs
            inputs.agenix.packages.${system}.default
            pkgs.lefthook
            pkgs.nixpkgs-fmt
          ];
          shellHook = ''
            lefthook install
          '';
        };
      };
    });
}
