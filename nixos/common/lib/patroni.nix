{
  lib,
  pkgs,
  config,
  ...
}: {
  environment.systemPackages = with pkgs; [
    patroni
    etcd_3_4
    coreutils
  ];

  services = {
    postgresql = {
      enableJIT = true;
      enable = false;
      enableTCPIP = true;
      settings = {
        listen_addresses = "100.64.0.1";
      };
      authentication = ''
        host    all             all             10.100.12.1/32          md5
        host    all             all             10.0.0.0/16             md5
        host    replication     all             10.100.12.1/32          md5
        host    replication     all             10.0.0.0/16             md5
        host    all             all             10.100.0.0/10  	      	md5
        host    replication     all             10.100.0.0/10           md5
        host    all             all             10.244.0.0/10           md5
      '';
    };

    etcd = {
      enable = true;
      initialClusterState = "existing";
      listenClientUrls = ["http://10.0.2.1:2379"];
      listenPeerUrls = ["http://10.0.2.1:2380"];
      initialCluster = [
        "worker-1=http://10.0.2.1:2380"
        "nordgedanken=http://10.0.1.2:2380"
      ];
      extraConf = {
        "UNSUPPORTED_ARCH" = "arm64";
        "ENABLE_V2" = "true";
      };
    };

    patroni = {
      enable = true;
      nodeIp = "10.0.2.1";
      name = "worker-1";
      scope = "cluster-1";
      postgresqlPackage = pkgs.postgresql_14;

      settings = {
        postgresql = {
          listen = lib.mkForce "127.0.0.1,10.0.2.1:5432";
          parameters = {
            max_connections = "300";
            superuser_reserved_connections = "3";

            shared_buffers = "4096 MB";
            work_mem = "32 MB";
            maintenance_work_mem = "320 MB";
            huge_pages = "off";
            effective_cache_size = "11 GB";
            effective_io_concurrency = "100"; # concurrent IO only really activated if OS supports posix_fadvise function
            random_page_cost = "1.25"; # speed of random disk access relative to sequential access (1.0)

            # Monitoring
            shared_preload_libraries = "pg_stat_statements"; # per statement resource usage stats
            track_io_timing = "on"; # measure exact block IO times
            track_functions = "pl"; # track execution times of pl-language procedures if any

            # Replication
            wal_level = "replica"; # consider using at least "replica"
            max_wal_senders = "10";
            synchronous_commit = "on";

            # Checkpointing:
            checkpoint_timeout = "15 min";
            checkpoint_completion_target = "0.9";
            max_wal_size = "1024 MB";
            min_wal_size = "512 MB";

            # WAL archiving
            archive_mode = "on"; # having it on enables activating P.I.T.R. at a later time without restart›
            archive_command = "${pkgs.coreutils}/bin/true"; # not doing anything yet with WAL-s

            # WAL writing
            wal_compression = "on";
            wal_buffers = "-1"; # auto-tuned by Postgres till maximum of segment size (16MB by default)
            wal_writer_delay = "200ms";
            wal_writer_flush_after = "1MB";
            wal_keep_size = "3650 MB";

            # Background writer
            bgwriter_delay = "200ms";
            bgwriter_lru_maxpages = "100";
            bgwriter_lru_multiplier = "2.0";
            bgwriter_flush_after = "0";

            # Parallel queries:
            max_worker_processes = "14";
            max_parallel_workers_per_gather = "7";
            max_parallel_maintenance_workers = "7";
            max_parallel_workers = "14";
            parallel_leader_participation = "on";

            # Advanced features
            enable_partitionwise_join = "on";
            enable_partitionwise_aggregate = "on";
            jit = "on";
            max_slot_wal_keep_size = "1000 MB";
            track_wal_io_timing = "on";
          };
        };
        etcd = {
          hosts = [
            "10.0.2.1:2379"
            "10.0.1.2:2379"
          ];
        };
        tags = {
          nofailover = false;
          noloadbalance = false;
          clonefrom = false;
          nosync = false;
        };
      };

      otherNodesIps = [
        "100.64.0.3"
      ];

      environmentFiles = {
        PATRONI_REPLICATION_USERNAME = config.sops.secrets."patroni/replication_username".path;
        PATRONI_REPLICATION_PASSWORD = config.sops.secrets."patroni/replication_password".path;
        PATRONI_SUPERUSER_USERNAME = config.sops.secrets."patroni/replication_superuser_username".path;
        PATRONI_SUPERUSER_PASSWORD = config.sops.secrets."patroni/replication_superuser_password".path;
      };
    };
  };

  # Ensure postgres can create a lockfile where it expects
  system.activationScripts = {
    postgresqlMkdir = {
      text = "mkdir -p /run/postgresql && chmod o+w /run/postgresql";
      deps = [];
    };
  };

  systemd.services.etcd.serviceConfig.ExecStart = lib.mkForce "${pkgs.etcd_3_4}/bin/etcd --force-new-cluster";
}
