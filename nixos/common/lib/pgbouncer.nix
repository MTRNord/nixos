{ lib, pkgs, config, ... }:
{
  environment.systemPackages = with pkgs; [
    pgbouncer
  ];
  users.users = {
    pgbouncer = {
      isSystemUser = true;
      description = "PgBouncer User";
    };
  };

  systemd.services.pgbouncer = {
    enable = true;
    after = [ "network-online.target" ];
    requires = [ "network-online.target" ];
    description = "PgBouncer - PostgreSQL connection pooler";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.pgbouncer}/bin/pgbouncer /etc/pgbouncer/pgbouncer.ini";
      Restart = "always";
      RestartSec = 5;
      TimeoutStopSec = 5;
      User = config.users.users.pgbouncer.name; # Set the user under which PgBouncer should run
      Group = config.users.users.pgbouncer.group; # Set the group under which PgBouncer should run
    };
  };

  environment.etc."pgbouncer/pgbouncer.ini" = {
    owner = config.users.users.pgbouncer.name;
    group = config.users.users.pgbouncer.name.group;
    text = ''
      [databases]
      db2 = host=10.100.0.2 port=5432
      db = host=10.100.0.1 port=5432

      [pgbouncer]
      listen_addr = ::
      listen_port = 5000

      ; Define your PgBouncer user and password here (replace with your actual values)
      auth_type = hba
      auth_hba_file = ${services.patroni.postgresqlDataDir}/pg_hba.conf

      ; Connection Pooling Settings
      pool_mode = transaction
      max_client_conn = 200
      min_pool_size = 5
      reserve_pool_size = 5
    '';
  };
}
