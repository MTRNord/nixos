# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)

{ inputs, outputs, lib, config, pkgs, ... }: {
  # You can import other NixOS modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/nixos):
    # outputs.nixosModules.example

    # Or modules from other flakes (such as nixos-hardware):
    # inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-pc-ssd

    inputs.impermanence.nixosModules.impermanence

    # You can also split up your configuration and import pieces of it here:
    # ./users.nix

    # Import your generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix

    ../common/sops.nix
    ../common/common.nix
    ../common/server.nix
    ./darlings.nix
    ./boot.nix

    ../common/lib/shell.nix
    ../common/lib/envoy.nix
    ../common/lib/fail2ban.nix
    ../common/lib/podman.nix
    ../common/lib/asterisk.nix
    ../common/lib/pgadmin.nix
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;

      asterisk = {
        withOpus = true;
      };

      permittedInsecurePackages = [
        "nodejs-16.20.2"
      ];
    };
  };

  nix = {
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;

    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Deduplicate and optimize nix store
      auto-optimise-store = true;
      # Sandbox
      sandbox = true;
      # Build locally
      trusted-substituters = [ ];
      substituters = [ ];
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 60d";
    };

  };

  # Broken
  systemd.network.wait-online.enable = false;
  systemd.network = {
    netdevs = {
      floating1 = {
        enable = true;
        netdevConfig = {
          Kind = "dummy";
          Name = "floating1";
        };
      };
    };
    networks = {
      floating1 = {
        enable = true;
        name = "floating1";
        address = [ ];
        matchConfig = {
          Name = "floating1";
        };
      };
    };
  };

  networking = {
    hostName = "worker-1";
    enableIPv6 = true;
    useNetworkd = true;
    useDHCP = true;
    # networkmanager.enable = true;

    nat = {
      enable = true;
      enableIPv6 = true;
      externalInterface = "enp1s0";
      internalInterfaces = [ "wg0" ];
    };

    nameservers = [ "8.8.8.8" "8.8.4.4" ];

    wg-quick.interfaces = {
      wg0 = {
        address = [ "10.100.0.1/24" "fe99:13::1/64" ];
        listenPort = 51820;
        privateKeyFile = config.sops.secrets."wireguard/private_key".path;
        table = "off";

        peers = [
          {
            publicKey = "M+OpQ/umgERHB+K6JJkszVChrRPqqYvMstbr28HRrSE=";
            allowedIPs = [
              "0.0.0.0/0"
              "::/0"
            ];
            endpoint = "95.217.202.35:51820";
          }
        ];
      };

    };

    firewall =
      let
        blockedV4 = [
          "158.101.19.243" # full-text search scraper https://macaw.social/@angilly/109597402157254670
          "207.231.106.226" # fediverse.network / fedi.ninja
          "45.81.20.80" # instances.social
          "198.58.122.231" # fedimapper.tedivm.com
          "142.93.3.121" # fedidb.org
          "45.158.40.164" # fedi.buzz
          "170.39.215.216" # fediverse.observer
          "87.157.136.163" # fedi_stats
          "94.31.103.67" # python/federation
          "45.56.100.29" # scottherr? same as :5a13
          "173.230.137.240" # scottherr@mastodon.social
          "138.37.89.34"
          "104.21.80.126" # gangstalking.services
          "172.67.181.16" # gangstalking.services
          "198.98.54.220" # ryona.agency
          "35.173.245.194"
          "99.105.215.234" # public tl
          "65.108.204.30" # unknown
          "65.109.31.111" # @fediverse@mastodont.cat
          "54.37.233.246" # fba.ryona.agency domain block scraper
          "185.244.192.119" # mooneyed.de / drow.be / bka.li blocklist scraper
          "23.24.204.110" # ryona tool fed.dembased.xyz / annihilation.social blocklist scraper
          "187.190.192.31" # ryona tool unfediblockthefedi.now
          "70.106.192.146" # blocklist scraper
          # https://openai.com/gptbot-ranges.txt
          "20.15.240.64/28"
          "20.15.240.80/28"
          "20.15.240.96/28"
          "20.15.240.176/28"
          "20.15.241.0/28"
          "20.15.242.128/28"
          "20.15.242.144/28"
          "20.15.242.192/28"
          "40.83.2.64/28"
        ];
        blockedV6 = [
          "2003:cb:ff2c:2700::1/64" # fedi_stats
          "2600:3c02::/64" # scottherr stats
          "2600:3c03::/64" # unknown, tries public tl access
          "2605:6400:10:1fe::1/64" # ryona.agency
          "2a01:4f9:5a:1cc4::2" # @fediverse@mastodont.cat
          "2604:a880:400:d1::1/64" # fedidb.org
          "2a01:4f8:162:6027::1/64" # blocklist scraper 
        ];
      in
      {
        checkReversePath = "loose";
        trustedInterfaces = [ "tailscale0" "floating1" "wg0" ];
        enable = true;
        allowPing = true;
        logRefusedConnections = false;
        allowedTCPPorts = [
          22 # ssh
          5060 # SIP
          8088
          80
          443
          51820
        ];
        allowedUDPPorts = [
          5060 # SIP
          config.services.tailscale.port
        ];

        allowedUDPPortRanges = [
          { from = 10000; to = 20000; }
        ];

        extraCommands =
          builtins.concatStringsSep "\n" (builtins.map (ip: "iptables -A INPUT -s ${ip} -j DROP") blockedV4) + "\n"
          + builtins.concatStringsSep "\n" (builtins.map (ip: "ip6tables -A INPUT -s ${ip} -j DROP") blockedV6);

        extraStopCommands =
          builtins.concatStringsSep "\n" (builtins.map (ip: "iptables -D INPUT -s ${ip} -j DROP") blockedV4) + "\n"
          + builtins.concatStringsSep "\n" (builtins.map (ip: "ip6tables -D INPUT -s ${ip} -j DROP") blockedV6);
      };
  };

  # packages that are not flakes
  environment.systemPackages = with pkgs; [
    unstable.forgejo-actions-runner
    config.services.headscale.package
    patroni
    etcd_3_4
  ];

  # Configure your system-wide user settings (groups, etc), add more users as needed.
  users = {
    #mutableUsers = false;
    users = {
      marcel = {
        isNormalUser = true;
        passwordFile = config.sops.secrets.marcel_initial_password.path;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKUzC9NeEc4voBeAO7YuQ1ewRKCS2iar4Bcm4cKoNKUH mtrnord@nordgedanken.dev"
        ];
        extraGroups = [ "wheel" ];
        shell = pkgs.zsh;
      };

      "root".passwordFile = config.sops.secrets.root_initial_password.path;
    };
  };

  services.gitea-actions-runner = {
    instances = {
      nordgedanken = {
        enable = false;
        url = "https://git.nordgedanken.dev";
        tokenFile = config.sops.secrets.forgejo_runner_token.path;
        labels = [ ];
        name = "worker-1";
      };
    };
  };

  systemd.services.gitea-runner-nordgedanken = {
    serviceConfig.SupplementaryGroups = [ config.users.groups.keys.name ];
  };


  # Restic Backup
  services.restic.backups = {
    storagebox = {
      passwordFile = config.sops.secrets.backup_password.path;
      paths = [
        "/persist"
      ];
      repository = "sftp://u362507@u362507.your-storagebox.de:22//backups/worker-1";
      timerConfig = {
        OnCalendar = "00:05";
        RandomizedDelaySec = "5h";
      };
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 5"
        "--keep-monthly 12"
      ];
      initialize = true;
    };
  };

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "support@nordgedanken.dev";

  services = {
    nginx = {
      enable = true;
      upstreams = {
        "asterisk_webrtc_ws" = {
          servers = {
            "127.0.0.1:8088" = { };
          };
        };
      };
      virtualHosts = {
        "pbx.midnightthoughts.space" = {
          forceSSL = true;
          enableACME = true;

          locations."/ws" = {
            proxyPass = "http://asterisk_webrtc_ws/ws";
            proxyWebsockets = true;
          };
          locations."/metrics" = {
            proxyPass = "http://asterisk_webrtc_ws/metrics";
          };
        };
        "headscale.midnightthoughts.space" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass =
              "http://localhost:${toString config.services.headscale.port}";
            proxyWebsockets = true;
          };
        };
        "lg.midnightthoughts.space" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass =
              "http://localhost:5001";
          };
        };
      };
      # streamConfig = ''
      #   match server_ok {
      #       status 200;
      #   }
      #   upstream postgres {
      #     zone postgres 64k;
      #     server 10.100.0.2:5432;
      #     server 10.100.0.1:5432;
      #   }
      #   server {
      #     listen 127.0.0.1:5000 tcp;
      #     listen 100.64.0.1:5000 tcp;
      #     listen 10.100.12.1:5000 tcp;
      #     proxy_pass postgres;
      #     health_check port=8008 interval=3 fails=3 passes=2 mandatory persistent  match=server_ok;
      #   }
      # '';
    };

    haproxy = {
      enable = false;
      config = ''
        global
          maxconn 300
          nbthread 6
          cpu-map 1/all 0-5

        defaults
          log global
          mode tcp
          retries 2
          timeout client 30m
          timeout connect 4s
          timeout server 1m
          timeout check 5s

        listen postgres
          bind 100.64.0.1:5000
          bind 127.0.0.1:5000
          bind 10.100.12.1:5000
          mode tcp
          option httpchk
          http-check expect status 200
          default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
          server pg_new1 10.100.0.2:5432 maxconn 300 check port 8008
          server pg_new2 10.100.0.1:5432 maxconn 300 check port 8008
      '';
    };

    discourse = {
      enable = true;
      database = {
        host = "postgres.internal.midnightthoughts.space";
        passwordFile = config.sops.secrets."discourse/db_password".path;
      };
      backendSettings = {
        db_port = 5000;
      };
      secretKeyBaseFile = config.sops.secrets."discourse/secret_key_base".path;
      mail = {
        outgoing = {
          port = 465;
          serverAddress = "mail.nordgedanken.dev";
          username = "support@miki.community";
          passwordFile = config.sops.secrets."discourse/mail_password".path;
          authentication = "login";
          forceTLS = true;
        };
        incoming.enable = false;
        contactEmailAddress = "support@miki.community";
      };
      redis = {
        host = "localhost";
      };
      hostname = "forum.miki.community";
      plugins = with config.services.discourse.package.plugins; [
        discourse-github
        discourse-solved
        discourse-docs
      ];
      siteSettings = {
        required = {
          title = "Matrix Projects Forum";
          contact_email = "support@miki.community";
          notification_email = "noreply@forum.miki.community";
        };
        login = {
          login_required = false;
          must_approve_users = false;
          enable_local_logins = true;
          enable_local_logins_via_email = true;
          allow_new_registrations = true;
        };
        spam = {
          notify_mods_when_user_silenced = true;
        };
        legal = {
          tos_url = "https://docs.draupnir.midnightthoughts.space/docs/code_of_conduct/";
        };
        plugins = {
          chat_enabled = false;
        };
      };
      admin = {
        username = "MTRNord";
        fullName = "Marcel";
        email = "mtrnord@nordgedanken.dev";
        passwordFile = config.sops.secrets."discourse/admin_password".path;
      };
    };
    tailscale = {
      enable = true;
      useRoutingFeatures = "both";
    };
    headscale = {
      enable = true;
      address = "0.0.0.0";
      port = 8080;

      settings = {
        logtail.enabled = false;
        server_url = "https://headscale.midnightthoughts.space";
        ip_prefixes = [ "fd7a:115c:a1e0::/48" "100.64.0.0/10" ];

        dns_config = {
          base_domain = "headscale.midnightthoughts.space";
          magic_dns = true;
          nameservers = [
            "8.8.8.8"
          ];
        };
      };
    };

    bird2 = {
      enable = true;
      config = ''
        router id 100.64.0.1;
        debug protocols all;

        protocol device {
        }

        protocol direct {
          ipv4;
          ipv6;
          interface "floating1";
        }

        protocol kernel {
          ipv4 {
            import all;
            export all;
          };
        }

        protocol kernel {
          ipv6 {
            import all;
            export all;
          };
        }

        protocol ospf v2 v4 {
          ipv4 {
            import all;
            export all;
          };
          graceful restart 1;
          area 0 {
            interface "wg0";
          };
        }

        protocol ospf v3 v6 {
          ipv6 {
            import all;
            export all;
          };
          graceful restart 1;
          area 0 {
            interface "wg0";
          };
        }
      '';
    };

    bird-lg = {
      proxy = {
        enable = true;
        allowedIPs = [ "100.64.0.1" ];
        listenAddress = "100.64.0.1:8000";
      };
      frontend = {
        enable = true;
        titleBrand = "Midnightthoughts infra";
        navbar.brand = "Midnightthoughts infra";
        listenAddress = "127.0.0.1:5001";
        domain = "lg.midnightthoughts.space";
        servers = [
          "worker-1"
          "nordgedanken"
        ];
      };
    };

    keepalived = {
      enable = true;
      extraGlobalDefs = ''
        lvs_id LVS_BACK
      '';
      # extraConfig = ''
      #   # Virtual Servers definitions
      #   virtual_server 10.100.12.1 5000 {
      #     delay_loop 10

      #     lb_algo wrr
      #     lb_kind DS

      #     persistence_timeout 10
      #     protocol TCP
      #     real_server 100.64.0.3 5432 {
      #         weight 1
      #         HTTP_GET {
      #           url {
      #             path /
      #           }

      #           connect_port 8008
      #           connect_timeout 3
      #           retry 3
      #           delay_before_retry 2
      #         }
      #     }
      #     real_server 100.64.0.1 5432 {
      #         weight 1
      #         HTTP_GET {
      #           url {
      #             path /
      #           }

      #           connect_port 8008
      #           connect_timeout 3
      #           retry 3
      #           delay_before_retry 2
      #         }
      #     }
      #   }
      # '';
      vrrpInstances = {
        VI_1 = {
          state = "BACKUP";
          interface = "wg0";
          virtualRouterId = 230;
          priority = 101;
          extraConfig = ''
            advert_int 1
          '';
          unicastSrcIp = "10.100.0.1";
          unicastPeers = [ "10.100.0.2" ];
          virtualIps = [
            {
              addr = "10.100.12.1/24";
              dev = "floating1";
            }
          ];
        };
      };
    };

    postgresql = {
      enableJIT = true;
      enable = false;
      enableTCPIP = true;
      settings = {
        listen_addresses = "100.64.0.1";
      };
      authentication = ''
        host    all             all             10.100.12.1/32          md5
        host    replication     all             10.100.12.1/32          md5
        host    all             all             10.100.0.0/10  	      	md5
        host    replication     all             10.100.0.0/10           md5
      '';
    };

    etcd = {
      enable = true;
      initialClusterState = "existing";
      listenClientUrls = [ "http://100.64.0.1:2379" ];
      listenPeerUrls = [ "http://100.64.0.1:2380" ];
      initialCluster = [
        "worker-1=http://100.64.0.1:2380"
        "nordgedanken=http://100.64.0.3:2380"
      ];
      extraConf = {
        "UNSUPPORTED_ARCH" = "arm64";
        "ENABLE_V2" = "true";
      };
    };
    patroni = {
      enable = true;
      nodeIp = "10.100.0.1";
      name = "worker-1";
      scope = "cluster-1";
      postgresqlPackage = pkgs.postgresql_14;

      settings = {
        postgresql = {
          listen = lib.mkForce "127.0.0.1,10.100.0.1:5432";
          parameters = {
            max_connections = "160";
            superuser_reserved_connections = "3";

            shared_buffers = "4096 MB";
            work_mem = "32 MB";
            maintenance_work_mem = "320 MB";
            huge_pages = "off";
            effective_cache_size = "11 GB";
            effective_io_concurrency = "200"; # concurrent IO only really activated if OS supports posix_fadvise function
            random_page_cost = "1.25"; # speed of random disk access relative to sequential access (1.0)

            # Monitoring
            shared_preload_libraries = "pg_stat_statements"; # per statement resource usage stats
            track_io_timing = "on"; # measure exact block IO times
            track_functions = "pl"; # track execution times of pl-language procedures if any

            # Replication
            wal_level = "replica"; # consider using at least "replica"
            max_wal_senders = "10";
            #synchronous_commit = "on";

            # Checkpointing: 
            checkpoint_timeout = "15 min";
            checkpoint_completion_target = "0.9";
            max_wal_size = "1024 MB";
            min_wal_size = "512 MB";

            # WAL archiving
            archive_mode = "on"; # having it on enables activating P.I.T.R. at a later time without restart›
            archive_command = "/bin/true"; # not doing anything yet with WAL-s

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
            max_worker_processes = "12";
            max_parallel_workers_per_gather = "6";
            max_parallel_maintenance_workers = "6";
            max_parallel_workers = "12";
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
            "100.64.0.3:2379"
            "100.64.0.1:2379"
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
      deps = [ ];
    };
  };

  systemd.services.etcd.serviceConfig.ExecStart = lib.mkForce "${pkgs.etcd_3_4}/bin/etcd";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.05";
}
