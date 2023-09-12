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

  services.kubernetes = {
    apiserverAddress = "https://[2a01:4f9:4a:451c:2::5]:6443";
    masterAddress = "[2a01:4f9:4a:451c:2::5]";
    roles = [ "node" ];
    proxy.enable = false;
    addons.dns.enable = true;
    easyCerts = false;
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
  services.kubernetes.flannel.enable = false;
}
