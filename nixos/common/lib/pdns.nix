{ lib, pkgs, config, ... }:
{
  services.powerdns = {
    enable = true;
  };

  networking.firewall.allowedTCPPorts = [ 8081 ];
}
