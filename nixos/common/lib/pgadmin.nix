{ lib, pkgs, config, ... }:
{
  services = {
    postgresql = {
      enableJIT = true;
      enable = false;
      enableTCPIP = true;
      settings = {
        listen_addresses = "100.64.0.1";
      };
      authentication = ''
        host    all             all             100.64.0.0/10           md5
        host    replication     all             100.64.0.0/10           md5
        host    all             all             10.100.12.1/32          md5
        host    replication     all             10.100.12.1/32          md5
      '';
    };
    pgadmin = {
      enable = true;
      settings = {
        DEFAULT_SERVER = "100.64.0.1";
      };
      initialEmail = "mtrnord@nordgedanken.dev";
      initialPasswordFile = config.sops.secrets.pgadmin_password.path;
    };
  };
}
