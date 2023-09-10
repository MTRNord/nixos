{ lib, pkgs, config, ... }:
{
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
        uid = 985
        gid = 983
        mode = "0644"
        src = "pgcat.toml.tmpl"
        dest = "/etc/pgcat/pgcat.toml"

        reload_cmd = "systemctl reload pgcat"

        keys = [
            "/", "/members/","/leader"
        ]
      '';
    };
    "confd/conf.d/pgbouncer.toml" = {
      text = ''
        [template]
        prefix = "/service/cluster-1"
        uid = 986
        gid = 984
        mode = "0644"
        src = "pgbouncer.tmpl"
        dest = "/etc/pgbouncer/pgbouncer.ini"

        reload_cmd = "systemctl reload pgbouncer"

        keys = [
            "/members/", "/leader"
        ]
      '';
    };
    "confd/templates/pgbouncer.tmpl" = {
      text = ''
        [databases]
        {{with get "/leader"}}{{$leader := .Value}}{{$leadkey := printf "/members/%s" $leader}}{{with get $leadkey}}{{$data := json .Value}}{{$hostport := base (replace (index (split $data.conn_url "/") 2) "@" "/" -1)}}{{ $host := base (index (split $hostport ":") 0)}}{{ $port := base (index (split $hostport ":") 1)}}* = host={{ $host }} port={{ $port }} pool_size=10{{end}}{{end}}

        [pgbouncer]
        listen_addr = *
        listen_port = 5000

        ignore_startup_parameters = extra_float_digits
        prepared_statement_cache_size = 10000

        auth_type = md5
        auth_hba_file = /etc/pgbouncer/pg_hba.conf
        auth_file = ${config.sops.secrets.pgbouncer_auth_file.path}

        pool_mode = transaction
        max_client_conn = 200
        default_pool_size = 10
        min_pool_size = 2
        reserve_pool_size = 5
      '';
    };
  };
  # Ensure confd can create a config
  system.activationScripts = {
    postgresqlMkdir = {
      text = "mkdir -p /etc/pgcat && chown pgcat:pgcat -R /etc/pgcat && chmod o+w /etc/pgcat";
      deps = [ ];
    };
  };
}
