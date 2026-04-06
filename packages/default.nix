{ self, inputs, ... }:

{
  perSystem = { system, pkgs, ... }:
    let
      orangepi3bDtb = "rockchip/rk3566-orangepi-3b-v2.1.dtb";
      orangepi3bIdbloaderSector = 64;
      orangepi3bUBootSector = 16384;

      pkgsARM = import inputs.nixpkgs {
        system = "aarch64-linux";
      };

      pkgsCross2311 = import inputs.nixpkgs-23-11 {
        localSystem = system;
        crossSystem = "aarch64-linux";
      };

      evalConfig = import "${inputs.nixpkgs}/nixos/lib/eval-config.nix";

      buildConfig = targetSystem: config:
        evalConfig {
          system = targetSystem;
          specialArgs = { inherit self inputs; };
          modules = [
            inputs.agenix.nixosModules.default
            self.nixosModules.firstBoot
            self.nixosModules.sdimage
            self.nixosModules.apply-overlay
          ] ++ config;
        };

      opi3bUboot = pkgsCross2311.callPackage ./orangepi-3b-uboot {
        src = inputs.orangepi-uboot;
        inherit (inputs) rkbin;
      };

      opi3bEval = buildConfig "aarch64-linux" [
        self.nixosModules.orangepi-3b-kernel
        ({ ... }: {
          sdImage.firmwarePartitionOffset = 32;
          sdImage.firmwareSize = 30;
          sdImage.compressImage = true;
          networking.networkmanager.enable = true;
          sdImage.populateFirmwareCommands = "";
          sdImage.extraPostbuild = ''
            dd if=${opi3bUboot}/idbloader.img of=$img seek=${toString orangepi3bIdbloaderSector} conv=notrunc status=none
            dd if=${opi3bUboot}/u-boot.itb of=$img seek=${toString orangepi3bUBootSector} conv=notrunc status=none
          '';
        })
      ];

    in
    {
      packages = rec {
        orangepi-3b-uboot = opi3bUboot;

        sdimage-orangepi-3b = opi3bEval.config.system.build.sdImage;
        orangepi-3b-image = sdimage-orangepi-3b;

        verify-orangepi-3b = pkgs.callPackage ./orangepi-3b-verify {
          imagePackage = orangepi-3b-image;
          kernelPackage = opi3bEval.config.boot.kernelPackages.kernel;
          ubootPackage = orangepi-3b-uboot;
          dtbPath = orangepi3bDtb;
          idbloaderSector = orangepi3bIdbloaderSector;
          uBootSector = orangepi3bUBootSector;
        };
      };
    };
}
