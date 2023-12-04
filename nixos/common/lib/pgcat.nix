{
  lib,
  pkgs,
  config,
  ...
}: {
  environment.systemPackages = with pkgs; [
    pgcat
    util-linux
  ];
  users = {
    groups.pgcat = {
      gid = 983;
    };
    users = {
      pgcat = {
        isSystemUser = true;
        description = "PgCat User";
        group = "pgcat";
        uid = 985;
      };
    };
  };

  systemd.services.pgcat = {
    enable = true;
    after = ["network-online.target"];
    requires = ["network-online.target"];
    description = "PgCat - PostgreSQL connection pooler";
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      LimitNOFILE = 65536;
      Environment = "RUST_LOG=info";
      ExecStart = "${pkgs.pgcat}/bin/pgcat /etc/pgcat/pgcat.toml";
      ExecReload = "${pkgs.util-linux}/bin/kill -s SIGHUP $MAINPID";
      Restart = "always";
      RestartSec = 1;
      TimeoutStopSec = 5;
      User = config.users.users.pgcat.name; # Set the user under which PgCat should run
      Group = config.users.users.pgcat.group; # Set the group under which PgCat should run
    };
  };
}
