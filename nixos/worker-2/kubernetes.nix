{
  lib,
  pkgs,
  config,
  ...
}: {
  environment.persistence."/persist" = {
    directories = [
      "/var/lib/kubernetes/"
      "/etc/kubernetes/"
      "/var/lib/kubelet"
      "/var/lib/etcd"
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
    nfs-utils
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

  networking.firewall.allowedTCPPorts = [
    4240
    4244
    4245
    4250
    10250
  ];
  networking.firewall.allowedUDPPorts = [
    8473
    51871
  ];

  services.kubernetes = {
    apiserverAddress = "https://[2a01:4f9:4a:451c:2::5]:6443";
    masterAddress = "[2a01:4f9:4a:451c:2::5]";
    roles = ["node"];
    proxy.enable = false;
    addons.dns.enable = true;
    easyCerts = false;
    caFile = config.sops.secrets.kubernetes_ca_file.path;
    dataDir = "/var/lib/kubelet";
    kubelet = {
      clusterDns = lib.mkForce "10.96.0.10";
      cni.configDir = "/persist/kubernetes/cni";
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
  services.kubernetes.kubelet.cni.packages = lib.mkForce [pkgs.cni-plugins];
}
