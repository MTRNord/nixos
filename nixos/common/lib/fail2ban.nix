{ lib, pkgs, config, ... }:
{
  services = {
    fail2ban = {
      enable = true;

      extraPackages = [ pkgs.ipset ];
      banaction = "iptables-ipset-proto6-allports";
      ignoreIP = [
        "148.251.63.154"
        "31.17.93.207"
      ];
      jails = {
        asterisk = ''
          enabled = true
          filter = asterisk
          action = iptables-allports[name=ASTERISK, protocol=all]
          maxretry = 2
          findtime = 21600
          bantime = 86400
        '';
      };
    };
  };
}
