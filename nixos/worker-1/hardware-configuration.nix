# This is just an example, you should generate yours with nixos-generate-config and put it in here.
{
  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };

  # Set your system kind (needed for flakes)
  nixpkgs.hostPlatform = "aarch64-linux";
}
