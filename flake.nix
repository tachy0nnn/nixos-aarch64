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

    bigtreetech-kernel = {
      url = "github:bigtreetech/linux/linux-6.1.y-cb1";
      flake = false;
    };

    devenv.url = "github:cachix/devenv";
    mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";
    nix2container.url = "github:nlewo/nix2container";
    nix2container.inputs.nixpkgs.follows = "nixpkgs";

    orangepi-uboot = {
      url = "github:orangepi-xunlong/u-boot-orangepi/v2017.09-rk3588";
      flake = false;
    };

    radxa-uboot = {
      url = "github:radxa/u-boot/stable-4.19-rock3";
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
          modules = [
            inputs.agenix.nixosModules.default
            self.nixosModules.orangepi-3b-kernel
            self.nixosModules.firstBoot
            ({ ... }: {
              networking.hostName = "opi3b";
            })
          ];
        };

        deploy.nodes.opi3b = {
          hostname = "192.168.3.163";
          sshUser = "root";
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
