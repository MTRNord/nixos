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
    listenHTTP = ":1360";
  };
  networking.firewall.allowedTCPPorts = [
    6697
    1360
  ];
}
