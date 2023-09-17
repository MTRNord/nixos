{ lib, pkgs, config, ... }:
{
  environment.persistence."/persist" = {
    directories = [
      "/var/lib/znc"
    ];
  };
  services.znc = {
    enable = true;
    modulePackages = [ pkgs.zncModules.clientbuffer ];
    confOptions = {
      useSSL = false;
      passBlock = ''
        <Pass password>
            Method = sha256
            Hash = cc4959a60c399f6db5f1b3239d88127f0fd0f95027364029ae8bb0080f77d75f
            Salt = 09a1RJwbtcUVr36j:;P-
        </Pass>
      '';
      nick = "MTRNord";
      userName = "MTRNord";
      port = 58457;
      networks = {
        "libera" = {
          server = "irc.libera.chat";
          port = 6697;
          useSSL = true;
          modules = [ "simple_away" ];
          channels = [ "fedora-buildsys" ];
        };
      };
    };

  };
  services = {
    nginx = {
      enable = true;
      upstreams = {
        "znc" = {
          servers = {
            "[::1]:58457" = { };
          };
        };
      };
      virtualHosts = {
        "znc.midnightthoughts.space" = {
          forceSSL = true;
          enableACME = true;

          locations."/" = {
            proxyPass = "http://znc";
          };
        };
      };
      streamConfig =
        let
          cert = config.security.acme.certs."${cfg.domainName}".directory + "/fullchain.pem";
          certKey = config.security.acme.certs."${cfg.domainName}".directory + "/key.pem";
          trustedCert = config.security.acme.certs."${cfg.domainName}".directory + "/chain.pem";
        in
        ''
          upstream znc {
            server [::1]:58457;
          }
          server {
            listen 6697 ssl;
            listen [::]:6697 ssl;
            ssl_certificate ${cert};
            ssl_certificate_key ${certKey};
            ssl_trusted_certificate ${trustedCert};
            proxy_pass znc;
          }
        '';
    };
  };
  networking.firewall.allowedTCPPorts = [
    6697
  ];
}
