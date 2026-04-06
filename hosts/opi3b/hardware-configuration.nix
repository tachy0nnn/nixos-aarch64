{ self, ... }:

{
  imports = [
    self.nixosModules.orangepi-3b-kernel
    self.nixosModules.firstBoot
  ];

  # This file contains hardware-specific configuration
  # that isn't shared with other potential OPi 3B variants.
}
