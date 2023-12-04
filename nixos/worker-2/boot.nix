{
  lib,
  pkgs,
  config,
  ...
}: {
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
        editor = false;
      };
      efi.canTouchEfiVariables = true;
    };
    kernelParams = ["ip=dhcp"];
    initrd = {
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
        hostKeys = ["/etc/secrets/initrd/ssh_host_ed25519_key"];
        # I'll just authorize all keys authorized post-boot.
        #authorizedKeys = config.users.users.marcel.openssh.authorizedKeys.keys;
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKUzC9NeEc4voBeAO7YuQ1ewRKCS2iar4Bcm4cKoNKUH mtrnord@nordgedanken.dev"
        ];
      };
    };
  };
}
