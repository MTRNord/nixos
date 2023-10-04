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
    ../common/lib/patroni.nix
    ../common/lib/confd.nix
    ../common/lib/pgbouncer.nix
    #../common/lib/pgadmin.nix
    ../common/lib/envoy.nix
    ../common/lib/fail2ban.nix
    ../common/lib/podman.nix
    ../common/lib/asterisk.nix
    ../common/lib/discourse.nix
    ../common/lib/github-runner.nix

    ./kubernetes.nix
    ./znc.nix
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
      "20-v6" = {
        matchConfig = {
          MACAddress = "96:00:02:44:cf:52";
        };
        address = [
          "49.13.24.105/32"
          "2a01:4f8:c012:492::1/64"
        ];
        routes = [
          { routeConfig.Gateway = "fe80::1"; }
          { routeConfig = { Gateway = "172.31.1.1"; GatewayOnLink = true; }; }

          # prevent some local traffic Hetzner doesn't like
          #{ routeConfig = { Destination = "172.16.0.0/12"; Type = "unreachable"; }; }
          { routeConfig = { Destination = "192.168.0.0/16"; Type = "unreachable"; }; }

          # { routeConfig = { Destination = "10.0.0.0/8"; Type = "unreachable"; }; }
          { routeConfig = { Destination = "fc00::/7"; Type = "unreachable"; }; }

        ];
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
          # big one
          {
            publicKey = "M+OpQ/umgERHB+K6JJkszVChrRPqqYvMstbr28HRrSE=";
            allowedIPs = [
              "10.100.12.1/24"
              "10.100.0.2/24"
              "10.100.0.202/24"
              "fe99:13::2/64"
              "fe99:13::202/64"
              "10.100.0.1/24"
              "10.100.0.201/24"
              "fe99:13::1/64"
              "fe99:13::201/64"
              "10.100.0.3/24"
              "10.100.0.203/24"
              "fe99:13::3/64"
              "fe99:13::203/64"
            ];
            persistentKeepalive = 25;
            endpoint = "95.217.202.35:51821";
          }
        ];
      };
      wg0 = {
        address = [ "10.100.0.201/24" "fe99:13::201/64" ];
        listenPort = 51821;
        privateKeyFile = config.sops.secrets."wireguard/private_key".path;
        table = "off";

        peers = [
          # worker-2
          {
            publicKey = "gswnnC4NQp0fXXGDhLaPVslCYPHMsXti0JloOzuGdn8=";
            allowedIPs = [
              "10.100.12.1/24"
              "10.100.0.2/24"
              "10.100.0.202/24"
              "fe99:13::2/64"
              "fe99:13::202/64"
              "10.100.0.1/24"
              "10.100.0.201/24"
              "fe99:13::1/64"
              "fe99:13::201/64"
              "10.100.0.3/24"
              "10.100.0.203/24"
              "fe99:13::3/64"
              "fe99:13::203/64"
            ];
            endpoint = "37.27.5.79:51821";
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
        allowedTCPPorts = [
          22 # ssh
          5060 # SIP
          8088
          80
          443
          51820
          51821
          9962
          9100
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
          + builtins.concatStringsSep "\n" (builtins.map (ip: "ip6tables -A INPUT -s ${ip} -j DROP") blockedV6) + "\n"
          + ''
            iptables -A nixos-fw -p tcp --source 10.245.0.0/16 -j nixos-fw-accept
            ip6tables -A nixos-fw -p tcp --source fd00::/104 -j nixos-fw-accept
          '';

        extraStopCommands =
          builtins.concatStringsSep "\n" (builtins.map (ip: "iptables -D INPUT -s ${ip} -j DROP") blockedV4) + "\n"
          + builtins.concatStringsSep "\n" (builtins.map (ip: "ip6tables -D INPUT -s ${ip} -j DROP") blockedV6) + "\n"
          + ''
            iptables -D nixos-fw -p tcp --source 10.245.0.0/16 -j nixos-fw-accept
            ip6tables -D nixos-fw -p tcp --source fd00::/104 -j nixos-fw-accept
          '';

      };
  };

  # packages that are not flakes
  environment.systemPackages = with pkgs; [
    unstable.forgejo-actions-runner
    config.services.headscale.package
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
      "node-yara-rs-runner" = {
        isNormalUser = false;
        isSystemUser = true;
        group = "node-yara-rs-runner";
      };
    };
    groups.node-yara-rs-runner = { };
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
            interface "wg0", "wg1";
          };
        }

        protocol ospf v3 v6 {
          ipv6 {
            import all;
            export all;
          };
          graceful restart 1;
          area 0 {
            interface "wg0", "wg1";
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
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.05";
}
