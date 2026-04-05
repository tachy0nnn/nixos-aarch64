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

      pantherUboot = pkgsCross2311.callPackage ./panther-x2-uboot {
        src = inputs.radxa-uboot;
        rkbin = inputs.rkbin-armbian;
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
        panther-x2-uboot = pantherUboot;

        linux-bigtreetech = pkgsARM.callPackage ./bigtreetech-kernel {
          bigtreetechSrc = inputs.bigtreetech-kernel;
          kernelPatches = with pkgsARM.kernelPatches; [
            bridge_stp_helper
            request_key_helper
          ];
        };

        fly-gemini-uboot = pkgsCross2311.callPackage ./fly-gemini-uboot { };

        sdimage-fly-gemini = (buildConfig "aarch64-linux" [
          self.nixosModules.fly-gemini-kernel
          ({ ... }: {
            sdImage.extraPostbuild = ''
              dd if="${fly-gemini-uboot}/u-boot-sunxi-with-spl.bin" of="$img" conv=fsync,notrunc bs=1024 seek=8
            '';
          })
        ]).config.system.build.sdImage;

        sdimage-bigtreetech = (buildConfig "aarch64-linux" [
          self.nixosModules.bigtreetech-kernel
          ({ ... }: {
            sdImage.extraPostbuild = ''
              dd if="${./bigtreetech-uboot/u-boot-sunxi-with-spl.bin}" of="$img" conv=fsync,notrunc bs=1024 seek=8
            '';
          })
        ]).config.system.build.sdImage;

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

        sdimage-panther-x2 = (buildConfig "aarch64-linux" [
          self.nixosModules.panther-x2-kernel
          ({ ... }: {
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
