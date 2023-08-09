# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)

{ inputs, outputs, lib, config, pkgs, ... }: {
  # You can import other NixOS modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/nixos):
    # outputs.nixosModules.example

    # Or modules from other flakes (such as nixos-hardware):
    # inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-ssd

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

  # btrfs boot
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.supportedFilesystems = [ "btrfs" ];
  hardware.enableAllFirmware = true;

  networking = {
    hostName = "worker-1";
    # networkmanager.enable = true;

    # Open ports in the firewall.
    firewall = {
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
    tree
    unzip
    unar
    git
    ripgrep
    clang
    llvm
    gcc
    binutils
    file
    go
    dos2unix
    cargo
    clippy
    rustc
    rustfmt
    home-manager
    zsh
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


  # SOPS
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  # This is using an age key that is expected to already be in the filesystem
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
  # This will generate a new key if the key specified above does not exist
  sops.age.generateKey = true;
  sops.defaultSopsFile = builtins.path { path = ./secrets/secrets.yaml; name = "worker-1-secrets"; };
  sops.secrets.marcel_initial_password.neededForUsers = true;

  environment.etc."ssh/ssh_host_ed25519_key" = {
    mode = "0600";
    source = config.sops.secrets.ssh_host_ed25519_key.path;
  };

  environment.etc."ssh/ssh_host_ed25519_key.pub" = {
    mode = "0644";
    source = config.sops.secrets.ssh_host_ed25519_key_pub.path;
  };


  environment.etc."ssh/ssh_host_rsa_key" = {
    mode = "0644";
    source = config.sops.secrets.ssh_host_rsa_key.path;
  };

  environment.etc."ssh/ssh_host_rsa_key.pub" = {
    mode = "0644";
    source = config.sops.secrets.ssh_host_rsa_key_pub.path;
  };

  # Configure your system-wide user settings (groups, etc), add more users as needed.
  users.users = {
    marcel = {
      # TODO: You can set an initial password for your user.
      # If you do, you can skip setting a root password by passing '--no-root-passwd' to nixos-install.
      # Be sure to change it (using passwd) after rebooting!
      #initialPassword = "correcthorsebatterystaple";
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

  # This setups a SSH server. Very important if you're setting up a headless system.
  # Feel free to remove if you don't need it.
  services.openssh = {
    enable = true;
    settings = {
      # Forbid root login through SSH.
      PermitRootLogin = "no";
      # Use keys only. Remove if you want to SSH using password (not recommended)
      PasswordAuthentication = false;
    };
  };

  # # Darling Erasure
  # environment.etc = {
  #   nixos.source = "/persist/etc/nixos";
  #   adjtime.source = "/persist/etc/adjtime";
  #   NIXOS.source = "/persist/etc/NIXOS";
  #   machine-id.source = "/persist/etc/machine-id";
  # };
  # systemd.tmpfiles.rules = [
  #   "L /etc/secrets/initrd/ssh_host_ed25519_key - - - - /persist/etc/secrets/initrd/ssh_host_ed25519_key"
  #   "L /etc/secrets/initrd/ssh_host_ed25519_key.pub - - - - /persist/etc/secrets/initrd/ssh_host_ed25519_key.pub"
  # ];
  # security.sudo.extraConfig = ''
  #   # rollback results in sudo lectures after each reboot
  #   Defaults lecture = never
  # '';
  # # Note `lib.mkBefore` is used instead of `lib.mkAfter` here.
  # boot.initrd.postDeviceCommands = pkgs.lib.mkBefore ''
  #   mkdir -p /mnt

  #   # We first mount the btrfs root to /mnt
  #   # so we can manipulate btrfs subvolumes.
  #   mount -o subvol=/ /dev/mapper/enc /mnt

  #   # While we're tempted to just delete /root and create
  #   # a new snapshot from /root-blank, /root is already
  #   # populated at this point with a number of subvolumes,
  #   # which makes `btrfs subvolume delete` fail.
  #   # So, we remove them first.
  #   #
  #   # /root contains subvolumes:
  #   # - /root/var/lib/portables
  #   # - /root/var/lib/machines
  #   #
  #   # I suspect these are related to systemd-nspawn, but
  #   # since I don't use it I'm not 100% sure.
  #   # Anyhow, deleting these subvolumes hasn't resulted
  #   # in any issues so far, except for fairly
  #   # benign-looking errors from systemd-tmpfiles.
  #   btrfs subvolume list -o /mnt/root |
  #   cut -f9 -d' ' |
  #   while read subvolume; do
  #     echo "deleting /$subvolume subvolume..."
  #     btrfs subvolume delete "/mnt/$subvolume"
  #   done &&
  #   echo "deleting /root subvolume..." &&
  #   btrfs subvolume delete /mnt/root

  #   echo "restoring blank /root subvolume..."
  #   btrfs subvolume snapshot /mnt/root-blank /mnt/root

  #   # Once we're done rolling back to a blank snapshot,
  #   # we can unmount /mnt and continue on the boot process.
  #   umount /mnt
  # '';

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.05";
}
