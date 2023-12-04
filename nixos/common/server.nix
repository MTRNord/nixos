{
  inputs,
  lib,
  pkgs,
  config,
  ...
}: {
  systemd = {
    network.enable = true;
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
  boot = {
    kernel.sysctl = {
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.ipv4.conf.all.forwarding" = true;
      "net.ipv6.conf.all.forwarding" = true;
      "net.ipv4.tcp_tw_reuse" = 1;
    };
    # Ensure a clean & sparkling /tmp on fresh boots.
    tmp.cleanOnBoot = true;
    # btrfs boot
    kernelPackages = inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.linuxPackages_latest;
    supportedFilesystems = ["btrfs"];
    initrd.supportedFilesystems = ["btrfs"];
  };

  hardware.enableAllFirmware = true;

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

  security.pam.loginLimits = [
    {
      domain = "*";
      type = "hard";
      item = "nofile";
      value = "8192";
    }
    {
      domain = "*";
      type = "soft";
      item = "nofile";
      value = "8192";
    }
  ];
}
