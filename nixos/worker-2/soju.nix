{
  lib,
  pkgs,
  config,
  ...
}: {
  environment.persistence."/persist" = {
    directories = [
      "/var/lib/soju"
    ];
  };
  services.soju = {
    enable = true;
    hostName = "soju.midnightthoughts.space";
    enableMessageLogging = true;
  };

  security.acme.certs."soju.midnightthoughts.space" = {
    group = services.soju.group;
    reloadServices = ["soju"];
    listenHTTP = ":1360";
  };
  networking.firewall.allowedTCPPorts = [
    6697
    1360
  ];
}
