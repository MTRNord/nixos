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
    };
  };
}
