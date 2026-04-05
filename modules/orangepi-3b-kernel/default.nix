{ config, lib, pkgs, ... }:

{
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.consoleLogLevel = lib.mkDefault 7;
  boot.kernelParams = [ "console=ttyS0,1500000" "console=tty0" "consoleblank=0" "brcmfmac.feature_disable=0x82000" ];
  boot.kernelModules = [ "brcmfmac" ];

  age.secrets.wifi-conn.file = ../../wifi-conn.age;
  system.activationScripts.nm-wifi-provisioning = {
    text = ''
      mkdir -p /etc/NetworkManager/system-connections
      cp ${config.age.secrets.wifi-conn.path} /etc/NetworkManager/system-connections/HomeWiFi.nmconnection
      chmod 600 /etc/NetworkManager/system-connections/HomeWiFi.nmconnection
      chown root:root /etc/NetworkManager/system-connections/HomeWiFi.nmconnection
    '';
  };

  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.powersave = false;
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHdRZp8XNCQwXOSiSpMLEuy7HLGeU1HXk3jck8zi0gtp"
  ];

  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      mesa
      libva-utils
    ];
  };
  services.xserver.videoDrivers = [ "modesetting" ];

  powerManagement.cpuFreqGovernor = "schedutil";
  boot.initrd.availableKernelModules = lib.mkForce [
    "ext4"
    "sd_mod"
    "sr_mod"
    "mmc_block"
    "dw_mmc_rockchip"
    "dw_mmc_pltfm"
    "dw_mmc"
    "sdhci_pltfm"
    "sdhci_of_dwcmshc"
    "ehci_hcd"
    "ohci_hcd"
    "xhci_hcd"
    "uas"
    "usb_storage"
  ];

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  environment.systemPackages = with pkgs; [
    usbutils
    htop
    vim
    git
    lm_sensors
    btop
    nvme-cli
    mesa-demos
    pciutils
    fastfetch
    uwufetch
    iw
  ];

  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  # DTB v2.1
  hardware.deviceTree.enable = true;
  hardware.deviceTree.name = "rockchip/rk3566-orangepi-3b-v2.1.dtb";
  hardware.enableRedistributableFirmware = true;

  # AP6256 firmware from Orange Pi's official repository
  hardware.firmware =
    let
      fw_bin = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/orangepi-xunlong/firmware/master/fw_bcm43456c5_ag.bin";
        hash = "sha256-pgMST/hiozJj3wzUYXIvlck0a6T2PF4AJAM8Mo2QOl4=";
      };
      fw_txt = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/orangepi-xunlong/firmware/master/nvram_ap6256.txt";
        hash = "sha256-WIQwtMLBZ8oDXxfadHi+w9SSJIcVJhDThdXMuPfAp18=";
      };
    in
    [
      (pkgs.stdenvNoCC.mkDerivation {
        name = "orangepi3b-v21-firmware";
        dontUnpack = true;
        installPhase = ''
          mkdir -p $out/lib/firmware/brcm
          cp ${fw_bin} $out/lib/firmware/brcm/brcmfmac43456-sdio.xunlong,orangepi-3b-v2.1.bin
          cp ${fw_txt} $out/lib/firmware/brcm/brcmfmac43456-sdio.xunlong,orangepi-3b-v2.1.txt
          ln -s brcmfmac43456-sdio.xunlong,orangepi-3b-v2.1.bin $out/lib/firmware/brcm/brcmfmac43456-sdio.xunlong.orangepi-3b-v2.1.bin
          ln -s brcmfmac43456-sdio.xunlong,orangepi-3b-v2.1.txt $out/lib/firmware/brcm/brcmfmac43456-sdio.xunlong.orangepi-3b-v2.1.txt
          ln -s brcmfmac43456-sdio.xunlong,orangepi-3b-v2.1.bin $out/lib/firmware/brcm/brcmfmac43456-sdio.bin
          ln -s brcmfmac43456-sdio.xunlong,orangepi-3b-v2.1.txt $out/lib/firmware/brcm/brcmfmac43456-sdio.txt
        '';
      })
    ];
}
