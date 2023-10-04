{ lib, pkgs, config, ... }:
{
  services.powerdns = {
    enable = true;
    extraConfig = ''
      launch=gsqlite3
      master=yes
      webserver-address=0.0.0.0
      webserver-allow-from=127.0.0.1,::1,10.244.0.0/16,31.17.243.193
      webserver-port=8081
      gsqlite3-database=/var/lib/pdns/pdns.db
    '';
  };

  networking.firewall.allowedTCPPorts = [ 8081 ];
}
