{
  lib,
  pkgs,
  config,
  ...
}: {
  environment.persistence."/persist" = {
    directories = [
      #"/var/lib/soju"
      "/var/lib/acme"
    ];
  };
  services.soju = {
    enable = true;
    hostName = "soju.midnightthoughts.space";
    enableMessageLogging = true;
    tlsCertificateKey = "/var/lib/acme/soju.midnightthoughts.space/key.pem";
    tlsCertificate = "/var/lib/acme/soju.midnightthoughts.space/fullchain.pem";
  };

  security.acme.certs."soju.midnightthoughts.space" = {
    reloadServices = ["soju"];
    webroot = "/var/lib/acme/.challenges";
    group = "soju";
  };
  users.users.nginx.extraGroups = ["acme"];
  services.nginx = {
    enable = true;
    virtualHosts = {
      "soju.midnightthoughts.space" = {
        # Catchall vhost, will redirect users to HTTPS for all vhosts
        serverAliases = ["*.midnightthoughts.space"];
        locations."/.well-known/acme-challenge" = {
          root = "/var/lib/acme/.challenges";
        };
      };
    };
  };
  networking.firewall.allowedTCPPorts = [
    6697
    1360
  ];
}
