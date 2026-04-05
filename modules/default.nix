{ self, inputs, lib, ... }:

{
  flake.nixosModules = {
    cross = ./cross;
    sdimage = ./sdimage;

    bigtreetech-kernel = ./bigtreetech-kernel;
    fly-gemini-kernel = ./fly-gemini-kernel;
    orangepi-3b-kernel = ./orangepi-3b-kernel;
    panther-x2-kernel = ./panther-x2-kernel;

    apply-overlay = {
      imports = [ ./apply-overlay ];
      _module.args.self = self;
    };

    firstBoot = {
      nix.nixPath = [
        "nixpkgs=${inputs.nixpkgs}"
      ];
      system.stateVersion = lib.mkDefault "25.11";

      services.openssh = {
        enable = true;
        settings.PermitRootLogin = "yes";
      };
      networking.networkmanager.enable = true;
      users.users.root.password = "nixos";
    };
  };
}
