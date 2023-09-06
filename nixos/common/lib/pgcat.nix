{ lib, pkgs, config, ... }:
{
  environment.systemPackages = with pkgs; [
    pgcat
  ];
  users = {
    groups.pgcat = { };
    users = {
      pgcat = {
        isSystemUser = true;
        description = "PgCat User";
        group = "pgcat";
      };
    };
  };

  systemd.services.pgcat = {
    enable = true;
    after = [ "network-online.target" ];
    requires = [ "network-online.target" ];
    description = "PgCat - PostgreSQL connection pooler";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      LimitNOFILE = 65536;
      Environment = "RUST_LOG=info";
      ExecStart = "${pkgs.pgcat}/bin/pgcat /etc/pgcat/pgcat.toml";
      ExecReload = "kill -s SIGHUP $MAINPID";
      Restart = "always";
      RestartSec = 1;
      TimeoutStopSec = 5;
      User = config.users.users.pgcat.name; # Set the user under which PgCat should run
      Group = config.users.users.pgcat.group; # Set the group under which PgCat should run
    };
  };

  services.confd = {
    enable = true;
    nodes = [
      "http://100.64.0.3:2379"
      "http://100.64.0.1:2379"
    ];
    prefix = "/service/cluster-1";
  };
  environment.etc = {
    "confd/conf.d/pgcat.toml" = {
      text = ''
        [template]
        prefix = "/service/cluster-1"
        owner = "pgcat"
        mode = "0644"
        src = "pgcat.tmpl"
        dest = "/etc/pgcat/pgcat.toml"

        reload_cmd = "systemctl reload pgcat"

        keys = [
            "/", "/members/","/leader"
        ]
      '';
    };
  };
}
