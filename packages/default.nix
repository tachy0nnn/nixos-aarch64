{ self, inputs, ... }:

{
  perSystem = { system, pkgs, ... }:
    let
      orangepi3bDtb = "rockchip/rk3566-orangepi-3b-v2.1.dtb";
      orangepi3bIdbloaderSector = 64;
      orangepi3bUBootSector = 16384;

      pkgsCross = import inputs.nixpkgs {
        localSystem = system;
        crossSystem = "aarch64-linux";
      };

      pkgsCross2311 = import inputs.nixpkgs-23-11 {
        localSystem = system;
        crossSystem = "aarch64-linux";
      };

      evalConfig = import "${inputs.nixpkgs}/nixos/lib/eval-config.nix";
      buildConfig = hostSystem: config:
        evalConfig {
          system = hostSystem;
          modules = [
            self.nixosModules.firstBoot
            self.nixosModules.sdimage
            self.nixosModules.apply-overlay
            self.nixosModules.cross
          ] ++ config;
        };

    in
    {
      packages = rec {
        linux-bigtreetech = pkgsCross.callPackage ./bigtreetech-kernel {
          bigtreetechSrc = inputs.bigtreetech-kernel;
          kernelPatches = with pkgsCross.kernelPatches;[
            bridge_stp_helper
            request_key_helper
          ];
        };

        orangepi-3b-uboot = pkgsCross2311.callPackage ./orangepi-3b-uboot {
          src = inputs.orangepi-uboot;
          inherit (inputs) rkbin;
        };

        panther-x2-uboot = pkgsCross.callPackage ./panther-x2-uboot {
          src = inputs.radxa-uboot;
          rkbin = inputs.rkbin-armbian;
        };

        fly-gemini-uboot = pkgsCross.callPackage ./fly-gemini-uboot { };

        sdimage-fly-gemini = (buildConfig system [
          self.nixosModules.fly-gemini-kernel

          ({ ... }: {
            # TODO: build uboot with nix
            sdImage.extraPostbuild = ''
              dd if="${fly-gemini-uboot}/u-boot-sunxi-with-spl.bin" of="$img" conv=fsync,notrunc bs=1024 seek=8
            '';
          })
        ]).config.system.build.sdImage;

        sdimage-bigtreetech = (buildConfig system [
          self.nixosModules.bigtreetech-kernel

          ({ ... }: {
            # TODO: build uboot with nix
            sdImage.extraPostbuild = ''
              dd if="${./bigtreetech-uboot/u-boot-sunxi-with-spl.bin}" of="$img" conv=fsync,notrunc bs=1024 seek=8
            '';
          })
        ]).config.system.build.sdImage;


        sdimage-orangepi-3b = (buildConfig system [
          self.nixosModules.orangepi-3b-kernel
          ({ ... }: {
            sdImage.firmwarePartitionOffset = 32;
            sdImage.firmwareSize = 30;
            sdImage.compressImage = true;
            networking.networkmanager.enable = true;
            sdImage.populateFirmwareCommands = "";

            sdImage.extraPostbuild = ''
              dd if=${orangepi-3b-uboot}/idbloader.img of=$img seek=${toString orangepi3bIdbloaderSector} conv=notrunc status=none
              dd if=${orangepi-3b-uboot}/u-boot.itb of=$img seek=${toString orangepi3bUBootSector} conv=notrunc status=none
            '';
          })
        ]).config.system.build.sdImage;

        orangepi-3b-image = sdimage-orangepi-3b;

        verify-orangepi-3b = pkgs.callPackage ./orangepi-3b-verify {
          imagePackage = orangepi-3b-image;
          kernelPackage = sdimage-orangepi-3b.config.boot.kernelPackages.kernel;
          ubootPackage = orangepi-3b-uboot;
          dtbPath = orangepi3bDtb;
          idbloaderSector = orangepi3bIdbloaderSector;
          uBootSector = orangepi3bUBootSector;
        };

        sdimage-panther-x2 = (buildConfig system [
          self.nixosModules.panther-x2-kernel

          ({ ... }: {
            # TODO: enable compress
            # Debug only
            sdImage.firmwarePartitionOffset = 32;
            sdImage.compressImage = false;
            sdImage.extraPostbuild = ''
              dd if=${panther-x2-uboot}/idbloader.img of=$img seek=64 conv=notrunc status=none
              dd if=${panther-x2-uboot}/u-boot.itb of=$img seek=16384 conv=notrunc status=none
            '';
          })
        ]).config.system.build.sdImage;
      };
    };
}
