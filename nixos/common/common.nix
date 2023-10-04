{ lib, pkgs, config, ... }:
{

  # General stuff
  time.timeZone = "Europe/Berlin";

  fonts.fontconfig.enable = lib.mkDefault false;
  environment.variables.BROWSER = "echo";
  sound.enable = false;
  powerManagement.cpuFreqGovernor = "performance";


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
    restic
    thefuck
    dnsutils
    jq
    compsize
    iperf
    qemu
    lsd
  ];

  # Write known-hosts
  programs.ssh.knownHosts = {
    "u362507.your-storagebox.de".publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA5EB5p/5Hp3hGW1oHok+PIOH9Pbn7cnUiGmUEBrCVjnAw+HrKyN8bYVV0dIGllswYXwkG/+bgiBlE6IVIBAq+JwVWu1Sss3KarHY3OvFJUXZoZyRRg/Gc/+LRCE7lyKpwWQ70dbelGRyyJFH36eNv6ySXoUYtGkwlU5IVaHPApOxe4LHPZa/qhSRbPo2hwoh0orCtgejRebNtW5nlx00DNFgsvn8Svz2cIYLxsPVzKgUxs8Zxsxgn+Q/UvR7uq4AbAhyBMLxv7DjJ1pc7PJocuTno2Rw9uMZi1gkjbnmiOh6TTXIEWbnroyIhwc8555uto9melEUmWNQ+C+PwAK+MPw==";
  };
}
