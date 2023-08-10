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

    # You can also split up your configuration and import pieces of it here:
    # ./users.nix

    # Import your generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix
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
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 60d";
    };
  };

  # General stuff
  time.timeZone = "Europe/Berlin";

  fonts.fontconfig.enable = lib.mkDefault false;
  environment.variables.BROWSER = "echo";
  sound.enable = false;

  systemd = {
    # Given that our systems are headless, emergency mode is useless.
    # We prefer the system to attempt to continue booting so
    # that we can hopefully still access it remotely.
    enableEmergencyMode = false;
    # For more detail, see:
    #   https://0pointer.de/blog/projects/watchdog.html
    watchdog = {
      # systemd will send a signal to the hardware watchdog at half
      # the interval defined here, so every 10s.
      # If the hardware watchdog does not get a signal for 20s,
      # it will forcefully reboot the system.
      runtimeTime = "20s";
      # Forcefully reboot if the final stage of the reboot
      # hangs without progress for more than 30s.
      # For more info, see:
      #   https://utcc.utoronto.ca/~cks/space/blog/linux/SystemdShutdownWatchdog
      rebootTime = "30s";
    };

    sleep.extraConfig = ''
      AllowSuspend=no
      AllowHibernation=no
    '';
  };

  # use TCP BBR has significantly increased throughput and reduced latency for connections
  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
  };

  # Ensure a clean & sparkling /tmp on fresh boots.
  boot.tmp.cleanOnBoot = true;

  # btrfs boot
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.supportedFilesystems = [ "btrfs" ];
  hardware.enableAllFirmware = true;

  networking = {
    hostName = "worker-1";
    # networkmanager.enable = true;

    # Open ports in the firewall.
    firewall = {
      allowPing = true;
      logRefusedConnections = false;
      enable = true;
      allowedTCPPorts = [
        22 # ssh
      ];
      allowedUDPPorts = [ ];
    };
  };

  # packages that are not flakes
  environment.systemPackages = with pkgs; [
    wget
    curl
    htop
    lsof
    git
    cargo
    clippy
    rustc
    rustfmt
    home-manager
    zsh
    restic
    thefuck
    dnsutils
    jq
  ];

  # Ensure /etc/shells is setup for zsh
  programs.zsh.enable = true;
  environment.shells = with pkgs; [ zsh ];

  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 10;
      editor = false;
    };
    efi.canTouchEfiVariables = true;
  };
  # TODO: Fix
  boot.kernelParams = [ "ip=dhcp" ];

  boot.initrd = {
    network.enable = true;
    luks.forceLuksSupportInInitrd = true;
    network.ssh = {
      enable = true;
      # Defaults to 22.
      port = 2222;
      shell = "/bin/cryptsetup-askpass";
      # The key is generated using `ssh-keygen -t ed25519 -N "" -f /etc/secrets/initrd/ssh_host_ed25519_key`
      #
      # Stored in plain text on boot partition, so don't reuse your host
      # keys. Also, make sure to use a boot loader with support for initrd
      # secrets (e.g. systemd-boot), or this will be exposed in the nix store
      # to unprivileged users.
      hostKeys = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
      # I'll just authorize all keys authorized post-boot.
      authorizedKeys = config.users.users.marcel.openssh.authorizedKeys.keys;
    };
  };

  # Write known-hosts
  programs.ssh.knownHosts = {
    "u362507.your-storagebox.de".publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA5EB5p/5Hp3hGW1oHok+PIOH9Pbn7cnUiGmUEBrCVjnAw+HrKyN8bYVV0dIGllswYXwkG/+bgiBlE6IVIBAq+JwVWu1Sss3KarHY3OvFJUXZoZyRRg/Gc/+LRCE7lyKpwWQ70dbelGRyyJFH36eNv6ySXoUYtGkwlU5IVaHPApOxe4LHPZa/qhSRbPo2hwoh0orCtgejRebNtW5nlx00DNFgsvn8Svz2cIYLxsPVzKgUxs8Zxsxgn+Q/UvR7uq4AbAhyBMLxv7DjJ1pc7PJocuTno2Rw9uMZi1gkjbnmiOh6TTXIEWbnroyIhwc8555uto9melEUmWNQ+C+PwAK+MPw==";
  };

  # This setups a SSH server. Very important if you're setting up a headless system.
  # Feel free to remove if you don't need it.
  services.openssh = {
    enable = true;
    settings = {
      # Forbid root login through SSH.
      PermitRootLogin = "no";
      # Use keys only. Remove if you want to SSH using password (not recommended)
      PasswordAuthentication = false;
      X11Forwarding = false;
      KbdInteractiveAuthentication = false;
      UseDns = false;
    };
  };

  # SOPS
  sops.age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
  sops.gnupg.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_rsa_key" ];
  # This is using an age key that is expected to already be in the filesystem
  sops.age.keyFile = "/persist/var/lib/sops-nix/key.txt";
  # This will generate a new key if the key specified above does not exist
  sops.age.generateKey = true;
  sops.defaultSopsFile = ./secrets/secrets.yaml;
  sops.secrets.marcel_initial_password.neededForUsers = true;
  sops.secrets.root_initial_password.neededForUsers = true;
  sops.secrets.ssh_host_ed25519_key = {
    mode = "0600";
    path = "/etc/ssh/ssh_host_ed25519_key";
  };
  sops.secrets.ssh_host_ed25519_key_pub = {
    mode = "0644";
    path = "/etc/ssh/ssh_host_ed25519_key.pub";
  };
  sops.secrets.ssh_host_rsa_key = {
    mode = "0600";
    path = "/etc/ssh/ssh_host_rsa_key";
  };
  sops.secrets.ssh_host_rsa_key_pub = {
    mode = "0644";
    path = "/etc/ssh/ssh_host_rsa_key.pub";
  };

  sops.secrets."ssh/marcel/id_ed25519" = {
    mode = "0600";
    owner = config.users.users.marcel.name;
    path = "/home/marcel/.ssh/id_ed25519";
  };

  sops.secrets."ssh/marcel/id_ed25519_pub" = {
    mode = "0644";
    owner = config.users.users.marcel.name;
    path = "/home/marcel/.ssh/id_ed25519.pub";
  };

  sops.secrets."ssh/root/id_ed25519" = {
    mode = "0600";
    owner = config.users.users.marcel.name;
    path = "/root/.ssh/id_ed25519";
  };

  sops.secrets."ssh/root/id_ed25519_pub" = {
    mode = "0644";
    owner = config.users.users.marcel.name;
    path = "/root/.ssh/id_ed25519.pub";
  };

  sops.secrets.backup_password = { };

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
        # TODO: Be sure to add any other groups you need (such as networkmanager, audio, docker, etc)
        extraGroups = [ "wheel" ];
        shell = pkgs.zsh;
      };
    };
  };

  users.users."root".passwordFile = config.sops.secrets.root_initial_password.path;

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

  # Darling Erasure
  environment.etc = {
    nixos.source = "/persist/etc/nixos";
    NIXOS.source = "/persist/etc/NIXOS";
    machine-id.source = "/persist/etc/machine-id";
    "secrets/initrd/ssh_host_ed25519_key" = {
      mode = "0600";
      source = "/persist/etc/secrets/initrd/ssh_host_ed25519_key";
    };
    "secrets/initrd/ssh_host_ed25519_key.pub" = {
      mode = "0644";
      source = "/persist/etc/secrets/initrd/ssh_host_ed25519_key.pub";
    };
  };
  systemd.tmpfiles.rules = [
    "L /home/marcel - - - - /persist/home/marcel"
    "L /var/lib/sops-nix/key.txt - - - - /persist/var/lib/sops-nix/key.txt"
  ];
  security.sudo.extraConfig = ''
    # rollback results in sudo lectures after each reboot
    Defaults lecture = never
  '';
  # Note `lib.mkBefore` is used instead of `lib.mkAfter` here.
  boot.initrd.postDeviceCommands = pkgs.lib.mkBefore ''
    mkdir -p /mnt

    # We first mount the btrfs root to /mnt
    # so we can manipulate btrfs subvolumes.
    mount -o subvol=/ /dev/mapper/enc /mnt

    # While we're tempted to just delete /root and create
    # a new snapshot from /root-blank, /root is already
    # populated at this point with a number of subvolumes,
    # which makes `btrfs subvolume delete` fail.
    # So, we remove them first.
    #
    # /root contains subvolumes:
    # - /root/var/lib/portables
    # - /root/var/lib/machines
    #
    # I suspect these are related to systemd-nspawn, but
    # since I don't use it I'm not 100% sure.
    # Anyhow, deleting these subvolumes hasn't resulted
    # in any issues so far, except for fairly
    # benign-looking errors from systemd-tmpfiles.
    btrfs subvolume list -o /mnt/root |
    cut -f9 -d' ' |
    while read subvolume; do
      echo "deleting /$subvolume subvolume..."
      btrfs subvolume delete "/mnt/$subvolume"
    done &&
    echo "deleting /root subvolume..." &&
    btrfs subvolume delete /mnt/root

    echo "restoring blank /root subvolume..."
    btrfs subvolume snapshot /mnt/root-blank /mnt/root

    # Once we're done rolling back to a blank snapshot,
    # we can unmount /mnt and continue on the boot process.
    umount /mnt
  '';

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.05";
}
