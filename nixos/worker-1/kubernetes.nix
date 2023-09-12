{ lib, pkgs, config, ... }:
{
  environment.persistence."/persist" = {
    directories = [
      "/var/lib/kubernetes/"
      "/etc/kubernetes/"
      "/var/lib/kubelet"
    ];
  };

  environment.systemPackages = with pkgs; [
    cri-o
    kubernetes
    iproute2
    ethtool
    socat
    cni
    conntrack-tools
    cri-tools
    cilium-cli
    k9s
  ];

  boot.kernelModules = [
    "iptable_nat"
    "iptable_filter"
    "xt_nat"
    "br_netfilter"
    "ip6table_mangle"
    "ip6table_raw"
    "ip6table_filter"
    "ip6_tables"
  ];


  services.kubernetes = {
    apiserverAddress = "https://[2a01:4f9:4a:451c:2::5]:6443";
    masterAddress = "[2a01:4f9:4a:451c:2::5]";
    roles = [ "node" ];
    proxy.enable = false;
    addons.dns.enable = true;
    easyCerts = false;
    caFile = config.sops.secrets.kubernetes_ca_file.path;
    dataDir = "/var/lib/kubelet";
    kubelet = {
      enable = true;
      kubeconfig = {
        server = "https://[2a01:4f9:4a:451c:2::5]:6443";
      };
      clientCaFile = config.sops.secrets.kubernetes_ca_client_file.path;
      extraOpts = "--fail-swap-on=false --kubeconfig=/etc/kubernetes/kubelet.conf --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --config=/var/lib/kubelet/config.yaml";
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
