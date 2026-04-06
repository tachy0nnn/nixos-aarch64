{ self, inputs, lib, ... }:

{
  flake.nixosModules = {
    cross = ./cross;
    sdimage = ./sdimage;

    orangepi-3b-kernel = ./hardware/orangepi-3b;

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
        settings = {
          PermitRootLogin = "prohibit-password"; # "yes"
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
        };
      };

      networking.networkmanager.enable = true;
      users.users.root.hashedPassword = "!";

      #users.users.root.password = "nixos";
    };
  };
}
