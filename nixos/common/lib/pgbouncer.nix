{ lib, pkgs, config, ... }:
{
  environment.systemPackages = with pkgs; [
    pgbouncer
  ];
  users = {
    groups.pgbouncer = { };
    users = {
      pgbouncer = {
        isSystemUser = true;
        description = "PgBouncer User";
        group = "pgbouncer";
        extraGroups = [ "patroni" ];
      };
    };
  };

  systemd.services.pgbouncer = {
    enable = true;
    after = [ "network-online.target" ];
    requires = [ "network-online.target" ];
    description = "PgBouncer - PostgreSQL connection pooler";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      LimitNOFILE = 8192;
      ExecStart = "${pkgs.pgbouncer}/bin/pgbouncer /etc/pgbouncer/pgbouncer.ini";
      Restart = "always";
      RestartSec = 5;
      TimeoutStopSec = 5;
      User = config.users.users.pgbouncer.name; # Set the user under which PgBouncer should run
      Group = config.users.users.pgbouncer.group; # Set the group under which PgBouncer should run
    };
  };

  environment.etc = {
    "pgbouncer/pg_hba.conf" = {

      user = config.users.users.pgbouncer.name;
      group = config.users.users.pgbouncer.group;
      text = ''
        host    all             all             127.0.0.1/32  	      	md5
        host    all             all             10.100.12.1/32          md5
        host    all             all             10.100.0.0/10  	      	md5
        host    all             all             10.244.0.0/10           md5
      '';
    };
    "pgbouncer/pgbouncer.ini" = {
      user = config.users.users.pgbouncer.name;
      group = config.users.users.pgbouncer.group;
      text = ''
        [databases]
        db2 = host=10.100.0.2 port=5432
        db = host=10.100.0.1 port=5432

        [pgbouncer]
        listen_addr = ::
        listen_port = 5000

        ; Define your PgBouncer user and password here (replace with your actual values)
        auth_type = hba
        auth_hba_file = /etc/pgbouncer/pg_hba.conf

        ; Connection Pooling Settings
        pool_mode = transaction
        max_client_conn = 200
        min_pool_size = 5
        reserve_pool_size = 5
      '';
    };
  };
}
