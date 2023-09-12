{ lib, pkgs, config, ... }:
{
  environment.persistence."/persist" = {
    directories = [
      "/var/lib/kubernetes/"
    ];
  };

  environment.systemPackages = with pkgs; [
    cri-o
    kubernetes
    iproute2
    ethtool
    socat
    cni
  ];

  boot.kernelModules = [ "br_netfilter" ];

  boot.kernel.sysctl = {
    # TODO IPV6/DualStack
    "net.ipv4.ip_forward" = 1;
  };

  virtualisation.cri-o.enable = true;

  services.kubernetes = {
    apiserverAddress = "https://[2a01:4f9:4a:451c:2::5]:6443";
    masterAddress = "[2a01:4f9:4a:451c:2::5]";
    roles = [ "node" ];
    kubelet = {
      enable = true;
      kubeconfig = {
        server = "https://[2a01:4f9:4a:451c:2::5]:6443";
      };
      extraOpts = "--fail-swap-on=false";
      taints = {
        "arm64" = {
          key = "arch";
          value = "arm64";
          effect = "NoSchedule";
        };
      };
    };
  };
}
