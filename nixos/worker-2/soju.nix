{
  lib,
  pkgs,
  config,
  ...
}: {
  environment.persistence."/persist" = {
    directories = [
      "/var/lib/soju"
      "/var/lib/acme"
    ];
  };
  services.soju = {
    enable = false;
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
  environment.etc."soju/config" = {
    user = "soju";
    group = "soju";
    text = ''
      listen :6697
      hostname soju.midnightthoughts.space
      tls /var/lib/acme/soju.midnightthoughts.space/fullchain.pem /var/lib/acme/soju.midnightthoughts.space/key.pem
      db sqlite3 /var/lib/soju/soju.db
      log fs /var/lib/soju/logs
    '';
  };

  systemd.services.soju = {
    description = "soju IRC bouncer";
    wantedBy = ["multi-user.target"];
    wants = ["network-online.target"];
    after = ["network-online.target"];
    serviceConfig = {
      Restart = "always";
      ExecStart = "${inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.soju}/bin/soju -config /etc/soju/config";
      StateDirectory = "soju";
      User = "soju";
      Group = "soju";
    };
  };
  networking.firewall.allowedTCPPorts = [
    6697
  ];
}
