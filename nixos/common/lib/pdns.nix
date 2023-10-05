{ lib, pkgs, config, ... }:
{
  sops.secrets.pdns_api_key = { };
  services.powerdns = {
    enable = true;
    secretFile = config.sops.secrets.pdns_api_key.path;
  };

  networking.firewall.allowedTCPPorts = [ 8081 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];
}
