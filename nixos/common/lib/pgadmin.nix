{ lib, pkgs, config, ... }:
{
  services = {
    postgresql.package = pkgs.postgresql_14;
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
