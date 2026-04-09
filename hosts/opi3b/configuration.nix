{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "opi3b";
  networking.nameservers = [
    "76.76.2.2"
    "76.76.10.2"
    "2606:1a40::2"
    "2606:1a40:1::2"
  ];
  networking.networkmanager.dns = "systemd-resolved";

  services.resolved = {
    enable = true;
    dnssec = "true";
    domains = [ "~." ];
    fallbackDns = [ "1.1.1.1" "8.8.8.8" ];
    extraConfig = ''
      DNSOverHTTPS=yes
      DNS=76.76.2.2#freedns.controld.com 76.76.10.2#freedns.controld.com 2606:1a40::2#freedns.controld.com 2606:1a40:1::2#freedns.controld.com
    '';
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  environment.systemPackages = with pkgs; [
    smartmontools
    iotop
    screen
    tmux
  ];
}
